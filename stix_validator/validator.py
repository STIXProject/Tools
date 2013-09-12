# Copyright (c) 2013, The MITRE Corporation. All rights reserved.
# See LICENSE.txt for complete terms.

import os
import re
from collections import defaultdict
from lxml import etree as et

class XmlValidator(object):
    NS_XML_SCHEMA_INSTANCE = "http://www.w3.org/2001/XMLSchema-instance"
    NS_XML_SCHEMA = "http://www.w3.org/2001/XMLSchema"
    
    def __init__(self, schema_dir=None, use_schemaloc=False):
        self.__imports = self._build_imports(schema_dir)
        self.__use_schemaloc = use_schemaloc
    
    def _get_target_ns(self, fp):
        '''Returns the target namespace for a schema file
        
        Keyword Arguments
        fp - the path to the schema file
        '''
        tree = et.parse(fp)
        root = tree.getroot()
        return root.attrib['targetNamespace'] # throw an error if it doesn't exist...we can't validate
        
    def _get_include_base_schema(self, list_schemas):
        '''Returns the root schema which defines a namespace.
        
        Certain schemas, such as OASIS CIQ use xs:include statements in their schemas, where two schemas
        define a namespace (e.g., XAL.xsd and XAL-types.xsd). This makes validation difficult, when we
        must refer to one schema for a given namespace.
        
        To fix this, we attempt to find the root schema which includes the others. We do this by seeing
        if a schema has an xs:include element, and if it does we assume that it is the parent. This is
        totally wrong and needs to be fixed. Ideally this would build a tree of includes and return the
        root node.
        
        Keyword Arguments:
        list_schemas - a list of schema file paths that all belong to the same namespace
        '''
        parent_schema = None
        tag_include = "{%s}include" % (self.NS_XML_SCHEMA)
        
        for fn in list_schemas:
            tree = et.parse(fn)
            root = tree.getroot()
            includes = root.findall(tag_include)
            
            if len(includes) > 0: # this is a hack that assumes if the schema includes others, it is the base schema for the namespace
                return fn
                
        return parent_schema
    
    def _build_imports(self, schema_dir):
        '''Given a directory of schemas, this builds a dictionary of schemas that need to be imported
        under a wrapper schema in order to enable validation. This returns a dictionary of the form
        {namespace : path to schema}.
        
        Keyword Arguments
        schema_dir - a directory of schema files
        '''
        if not schema_dir:
            return None
        
        imports = defaultdict(list)
        for top, dirs, files in os.walk(schema_dir):
            for f in files:
                if f.endswith('.xsd'):
                    fp = os.path.join(top, f)
                    target_ns = self._get_target_ns(fp)
                    imports[target_ns].append(fp)
        
        for k,v in imports.iteritems():
            if len(v) > 1:
                base_schema = self._get_include_base_schema(v)
                imports[k] = base_schema
            else:
                imports[k] = v[0]
    
        return imports
    
    def _build_wrapper_schema(self, import_dict):
        '''Creates a wrapper schema that imports all namespaces defined by the input dictionary. This enables
        validation of instance documents that refer to multiple namespaces and schemas
        
        Keyword Arguments
        import_dict - a dictionary of the form {namespace : path to schema} that will be used to build the list of xs:import statements
        '''
        schema_txt = '''<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="http://stix.mitre.org/tools/validator" elementFormDefault="qualified" attributeFormDefault="qualified"/>'''
        root = et.fromstring(schema_txt)
        
        tag_import = "{%s}import" % (self.NS_XML_SCHEMA)
        for ns, list_schemaloc in import_dict.iteritems():
            schemaloc = list_schemaloc
            schemaloc = schemaloc.replace("\\", "/")
            attrib = {'namespace' : ns, 'schemaLocation' : schemaloc}
            el_import = et.Element(tag_import, attrib=attrib)
            root.append(el_import)
    
        return root

    def _extract_schema_locations(self, root):
        schemaloc_dict = {}
        
        tag_schemaloc = "{%s}schemaLocation" % (self.NS_XML_SCHEMA_INSTANCE)
        schemaloc = root.attrib[tag_schemaloc].split()
        schemaloc_pairs = zip(schemaloc[::2], schemaloc[1::2])
        
        for ns, loc in schemaloc_pairs:
            schemaloc_dict[ns] = loc
        
        return schemaloc_dict
    
    def validate(self, instance_doc):
        '''Validates an instance documents.
        
        Returns a tuple of where the first item is the boolean validation
        result and the second is the validation error if there was one.
        
        Keyword Arguments
        instance_doc - a file-like object to be validated
        '''
        if not(self.__use_schemaloc or self.__imports):
            return (False, "No schemas to validate against! Try instantiating XmlValidator with use_schemaloc=True or setting the schema_dir")
        
        instance_doc = et.parse(instance_doc)
        instance_root = instance_doc.getroot()
        
        if self.__use_schemaloc:
            try:
                required_imports = self._extract_schema_locations(instance_root)
            except KeyError as e:
                return (False, "No schemaLocation attribute set on instance document. Unable to validate")
        else:
            required_imports = {}
            for prefix, ns in instance_root.nsmap.iteritems():
                schemaloc = self.__imports.get(ns)
                if schemaloc:
                    required_imports[ns] = schemaloc

        if not required_imports:
            return (False, "Unable to determine schemas to validate against")

        wrapper_schema_doc = self._build_wrapper_schema(import_dict=required_imports)
        xmlschema = et.XMLSchema(wrapper_schema_doc)
        
        try: 
            xmlschema.assertValid(instance_doc)
            return (True, None)
        except Exception as e:
            return (False, str(e))


class STIXValidator(XmlValidator):
    '''Schema validates STIX v1.0 documents and checks best practice guidance'''
    __stix_version__ = "1.0"
    
    PREFIX_STIX_CORE = 'stix'
    PREFIX_CYBOX_CORE = 'cybox'
    PREFIX_STIX_INDICATOR = 'indicator'
    
    NS_STIX_CORE = "http://stix.mitre.org/stix-1"
    NS_STIX_INDICATOR = "http://stix.mitre.org/Indicator-2"
    NS_CYBOX_CORE = "http://cybox.mitre.org/cybox-2"
    
    NS_MAP = {PREFIX_CYBOX_CORE : NS_CYBOX_CORE,
              PREFIX_STIX_CORE : NS_STIX_CORE,
              PREFIX_STIX_INDICATOR : NS_STIX_INDICATOR}
    
    def __init__(self, schema_dir=None, use_schemaloc=False, best_practices=False):
        super(STIXValidator, self).__init__(schema_dir, use_schemaloc)
        self.best_practices = best_practices
        
    def _check_id_presence_and_format(self, instance_doc):
        return_dict = {'no_id' : [],
                       'format' : []}
        
        elements_to_check = ['stix:Campaign',
                             'stix:Course_Of_Action',
                             'stix:Exploit_Target',
                             'stix:Incident',
                             'stix:Indicator',
                             'stix:STIX_Package',
                             'stix:Thread_Actor',
                             'stix:TTP',
                             'cybox:Observable',
                             'cybox:Object',
                             'cybox:Event',
                             'cybox:Action']
    
        for tag in elements_to_check:
            xpath = ".//%s" % (tag)
            elements = instance_doc.xpath(xpath, namespaces=self.NS_MAP)
            
            for e in elements:
                try:
                    if not re.match(r'\w+:\w+-', e.attrib['id']): # not the best regex
                        return_dict['format'].append(e)
                except KeyError as ex:
                    return_dict['no_id'].append(e)
            
        return return_dict
    
    def _check_duplicate_ids(self, instance_doc):
        dict_id_nodes = defaultdict(list)
        dup_dict = {}
        xpath_all_nodes_with_ids = "//*[@id]"
        
        all_nodes_with_ids = instance_doc.xpath(xpath_all_nodes_with_ids)
        for node in all_nodes_with_ids:
            dict_id_nodes[node.attrib['id']].append(node)
        
        for k,v in dict_id_nodes.iteritems():
            if len(v) > 1:
                dup_dict[k] = v
        
        return dup_dict
    
    def _check_idref_resolution(self, instance_doc):
        list_unresolved_ids = []
        xpath_all_idrefs = "//*[@idref]"
        xpath_all_ids = "//@id"
        
        all_idrefs = instance_doc.xpath(xpath_all_idrefs)
        all_ids = instance_doc.xpath(xpath_all_ids)
        
        for node in all_idrefs:
            if node.attrib['idref'] not in all_ids:
                list_unresolved_ids.append(node)
                
        return list_unresolved_ids
                
    def _check_idref_with_content(self, instance_doc):
        list_nodes = []
        xpath = "//*[@idref]"
        nodes = instance_doc.xpath(xpath)
        
        for node in nodes:
            if node.text or len(node) > 0:
                list_nodes.append(node)
                
        return list_nodes
    
    def _check_indicator_practices(self, instance_doc):
        list_indicators = []
        xpath = "//%s:Indicator | %s:Indicator" % (self.PREFIX_STIX_CORE, self.PREFIX_STIX_INDICATOR)
        
        nodes = instance_doc.xpath(xpath, namespaces=self.NS_MAP)
        for node in nodes:
            dict_indicator = {}
            if not node.attrib.get('idref'): # if this is not an idref node, look at its content
                if node.find('{%s}Title' % (self.NS_STIX_INDICATOR)) is None:
                    dict_indicator['title'] = False
                if node.find('{%s}Description' % (self.NS_STIX_INDICATOR)) is None:
                    dict_indicator['description'] = False
                if node.find('{%s}Type' % (self.NS_STIX_INDICATOR)) is None:
                    dict_indicator['type'] = False
                if node.find('{%s}Valid_Time_Position' % (self.NS_STIX_INDICATOR)) is None:
                    dict_indicator['valid_time_position'] = False
                if node.find('{%s}Indicated_TTP' % (self.NS_STIX_INDICATOR)) is None:
                    dict_indicator['indicated_ttp'] = False
                if node.find('{%s}Confidence' % (self.NS_STIX_INDICATOR)) is None:
                    dict_indicator['confidence'] = False
                
                if dict_indicator:
                    dict_indicator['id'] = node.attrib.get('id')
                    dict_indicator['node'] = node
                    list_indicators.append(dict_indicator)
                
        return list_indicators
 
    def check_best_practices(self, instance_doc):
        instance_doc.seek(0)
        tree = et.parse(instance_doc)
        root = tree.getroot()
        
        list_unresolved_idrefs = self._check_idref_resolution(root)
        dict_duplicate_ids = self._check_duplicate_ids(root)
        dict_presence_and_format = self._check_id_presence_and_format(root)
        list_idref_with_content = self._check_idref_with_content(root)
        list_indicators = self._check_indicator_practices(root)
        
        return {'unresolved_idrefs' : list_unresolved_idrefs,
                'duplicate_ids' : dict_duplicate_ids,
                'missing_ids' : dict_presence_and_format['no_id'],
                'id_format' : dict_presence_and_format['format'],
                'idref_with_content' : list_idref_with_content,
                'indicator_suggestions' : list_indicators }
    
    def validate(self, instance_doc):
        '''Validates a STIX document and checks best practice guidance if STIXValidator
        was initialized with best_practices=True.
        
        Best practices will not be checked if the document is schema-invalid.
        
        Returns a tuple of (bool, str, dict) for (is valid, validation error, best practice suggestions).
        
        Keyword Arguments
        instance_doc - a file-like object for a STIX instance document
        '''
        (isvalid, validation_error) = super(STIXValidator, self).validate(instance_doc)
        
        if self.best_practices and isvalid:
            best_practice_warnings = self.check_best_practices(instance_doc)
        else:
            best_practice_warnings = None
            
        return (isvalid, validation_error, best_practice_warnings)
        
 