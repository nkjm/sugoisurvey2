@isTest
private class validate_guest_cascade_delete {
    static testmethod void validate_guest_cascade_delete(){
        session__c session = validation_data.createDummySession('poiqjefpoerfj', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        update session;
        guest__c g = [select id from guest__c where session__c = :session.id and first_name__c = 'uruffjjfr'];
        system.assertEquals(2, [select id from custom_survey_answer__c where guest__c = :g.id].size());
        
        delete g;
        system.assertEquals(0, [select id from custom_survey_answer__c where guest__c = :g.id].size());
    }
}