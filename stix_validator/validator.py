# Copyright (c) 2013, The MITRE Corporation. All rights reserved.
# See LICENSE.txt for complete terms.

import os
from collections import defaultdict
from lxml import etree as et

NS_XML_SCHEMA_INSTANCE = "http://www.w3.org/2001/XMLSchema-instance"
NS_XML_SCHEMA = "http://www.w3.org/2001/XMLSchema"

class XmlValidator(object):
    
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
        tag_include = "{%s}include" % (NS_XML_SCHEMA)
        
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
        
        tag_import = "{%s}import" % (NS_XML_SCHEMA)
        for ns, list_schemaloc in import_dict.iteritems():
            schemaloc = list_schemaloc
            schemaloc = schemaloc.replace("\\", "/")
            attrib = {'namespace' : ns, 'schemaLocation' : schemaloc}
            el_import = et.Element(tag_import, attrib=attrib)
            root.append(el_import)
    
        return root

    def _extract_schema_locations(self, root):
        schemaloc_dict = {}
        
        tag_schemaloc = "{%s}schemaLocation" % (NS_XML_SCHEMA_INSTANCE)
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

 