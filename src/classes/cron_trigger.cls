global class cron_trigger implements Schedulable{
    global integer interval = 1;
    
    global void execute(SchedulableContext SC) {
        // notify guest registration
        chatter_notification.notify_registration_to_record_feed_for_pending_guest();

        // schedule next copy
        Datetime next = Datetime.now().addMinutes(this.interval);
        string sch = string.valueOf(next.second()) + ' ' + string.valueOf(next.minute()) + ' ' + string.valueOf(next.hour()) + ' ' + string.valueOf(next.day()) + ' ' + string.valueOf(next.month()) + ' ?';
        id cron_trigger_id = System.schedule('Sugoi Survey Cron Trigger v5.0 - ' + sch, sch, new cron_trigger());

        // update config
        config__c config = config__c.getOrgDefaults();
        config.cron_trigger_id__c = cron_trigger_id;
        upsert config;
        
        // abort this job
        if (!Test.isRunningTest()){
            System.abortJob(sc.getTriggerId());
        }
    }
}