public with sharing virtual class html5tCtl {
    private class sexception extends exception {}

    public html5tCtl(){}

    public class objField {
        public string name;
        public string relationshipName;
        public string label;
        public string type;
        public string parentObj;
        public boolean isNameField;
        public boolean isNillable;
        public boolean isAccessible;
        public boolean isCreateable;
        public boolean isUpdateable;
        public boolean isAutoNumber;
        public list<map<string, string>> picklistItems;
    }

    public class relatedObject {
        public string name;
        public string label;
        public string fieldName;
        public string relationshipName;
    }


    ////
    //// Remoting Methods
    ////

    @remoteAction
    public static list<objField> get_objFields(string objName){
        list<objField> oflds = new list<objField>();
        set<string> exclude_fields = new set<string>{'createddate','ownerid','createdbyid','lastmodifieddate','isdeleted','systemmodstamp','lastmodifiedbyid','lastvieweddate','lastreferenceddate'};
        list<schema.describeFieldResult> frs = new list<schema.describeFieldResult>();
        map<string, schema.sObjectField> om = schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
        for (string k : om.keySet()){
            if (exclude_fields.contains(k)){
                continue;
            }
            frs.add(om.get(k).getDescribe());
        }
        for (schema.describeFieldResult r : frs){
            if (r == null){
                continue;
            }
            objField ofld = new objField();
            ofld.name = r.getName();
            ofld.relationshipName = r.getRelationshipName();
            ofld.label = r.getLabel();
            ofld.type = String.valueOf(r.getType());
            ofld.isNameField = r.isNameField();
            ofld.isNillable = r.isNillable();
            ofld.isAccessible = r.isAccessible();
            ofld.isCreateable = r.isCreateable();
            ofld.isUpdateable = r.isUpdateable();
            ofld.isAutoNumber = r.isAutoNumber();

            // If this field is picklist, we include its label, value pair.
            if (ofld.type == 'picklist' || ofld.type == 'multipicklist'){
                list<map<string, string>> picklist_items = new list<map<string, string>>();
                for (schema.picklistEntry ple : r.getPicklistValues()){
                    map<string, string> mm = new map<string, string>();
                    mm.put('label', ple.getLabel());
                    mm.put('value', ple.getValue());
                    mm.put('isActive', String.valueOf(ple.isActive()));
                    mm.put('isDefaultValue', String.valueOf(ple.isDefaultValue()));
                    picklist_items.add(mm);
                }
                ofld.picklistItems = picklist_items;
            }

            // If this field is reference, we include its parnet object name
            if (ofld.type == 'reference'){
                ofld.parentObj = r.getReferenceTo()[0].getDescribe().getName();
            }
            
            oflds.add(ofld);
        }
        return oflds;
    }

    @remoteAction
    public static list<map<string, string>> get_objects(boolean all){
        list<map<string, string>> l = new list<map<string, string>>();
        for (schema.describeSObjectResult r : getObjects(all)){
            map<string, string> m = new map<string, string>();
            m.put('name', r.getName());
            m.put('label', r.getLabel());
            l.add(m);
        }
        return l;
    }

    public static list<schema.describeSObjectResult> getObjects(boolean all){
        list<Schema.DescribeSObjectResult> ors = new list<Schema.DescribeSObjectResult>();
        map<string, schema.SObjectType> m = schema.getGlobalDescribe();
        for (string k : m.keySet()){
            if (all){
                ors.add(m.get(k).getDescribe());
            } else {
                if (k.endsWith('__c') && k != 'report_mapping__c'){
                    ors.add(m.get(k).getDescribe());
                }
            }
        }
        return ors;
    }

    @remoteAction
    public static list<relatedObject> get_relatedObjects(string objName){
        set<string> exclude_objects = new set<string>{'AttachedContentDocument','Attachment','CombinedAttachment','ContentDocumentLink','ContentVersion','EntitySubscription','FeedComment','FeedItem','Note','NoteAndAttachment','ProcessInstance','ProcessInstanceHistory','TopicAssignment'};
        list<relatedObject> ros = new list<relatedObject>();
        for (schema.childRelationship cr : schema.getGlobalDescribe().get(objName).getDescribe().getChildRelationships()){
            if (exclude_objects.contains(cr.getChildSObject().getDescribe().getName())){
                continue;
            }
            relatedObject ro = new relatedObject();
            ro.label = cr.getChildSObject().getDescribe().getLabel();
            ro.name = cr.getChildSObject().getDescribe().getName();
            ro.relationshipName = cr.getRelationshipName();
            ro.fieldName = cr.getField().getDescribe().getName();
            ros.add(ro);
        }
        return ros;
    }
}