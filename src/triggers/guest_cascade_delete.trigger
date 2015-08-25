trigger guest_cascade_delete on Guest__c (before delete) {
    for (guest__c g : Trigger.old){
        delete [select id from custom_survey_answer__c where guest__c = :g.id];
    }
}