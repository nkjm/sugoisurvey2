@isTest
public with sharing class validate_html5tCtl {
    private static testmethod void test_get_objFields(){
        list<html5tCtl.objField> fs = html5tCtl.get_objFields('Account');
        boolean phone_found = false;
        boolean email_found = false;
        for (html5tCtl.objField f : fs){
            if (f.name == 'Phone'){
                phone_found = true;
            }
            if (f.name == 'Email'){
                email_found = true;
            }
        }
        system.assertEquals(true, phone_found);
        system.assertEquals(false, email_found);
    }

    private static testmethod void test_get_objects(){
        list<map<string, string>> os = html5tCtl.get_objects(true);
        boolean user_found = false;
        for (map<string, string> o : os){
            if (o.get('name') == 'User'){
                user_found = true;
            }
        }
        system.assertEquals(true, user_found);

        os = html5tCtl.get_objects(false);
        user_found = false;
        for (map<string, string> o : os){
            if (o.get('name') == 'User'){
                user_found = true;
            }
        }
        system.assertEquals(false, user_found);
    }

    private static testmethod void test_get_relatedObjects(){
        list<html5tCtl.relatedObject> ros = html5tCtl.get_relatedObjects('Account');
        boolean contact_found = false;
        boolean noteAndAttachment_found = false;
        for (html5tCtl.relatedObject ro : ros){
            if (ro.name == 'Contact'){
                contact_found = true;
            }
            if (ro.name == 'NoteAndAttachment'){
                noteAndAttachment_found = true;
            }
        }
        system.assertEquals(true, contact_found);
        system.assertEquals(false, noteAndAttachment_found);
    }
}