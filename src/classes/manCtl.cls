global with sharing class manCtl {
    private class sexception extends exception {}
    
    @remoteAction 
    global static void generate_config(string current_url){
        config__c config = config__c.getOrgDefaults();
        
        // Quit if app has been initialized.
        if (config.initialized__c == true && config.need_re_initialization__c == false){
            sexception se = new sexception();
            se.setMessage(system.label.already_initialized);
            throw se;
        }
        
        // Quit if sites has not been activated yet.
        list<site> sites = [select status, subdomain from site where urlPathPrefix = 'sugoisurvey'];
        if (sites.size() == 0 || sites[0].subdomain == null || sites[0].status != 'Active'){
            sexception se = new sexception();
            se.setMessage(system.label.sites_not_activated);
            throw se;
        }
        
        // Identify the Edition of this Org
        string edition = [select OrganizationType from organization].OrganizationType;
        
        // Identify whether this org is production or sandbox
        string hostname = current_url.split('/',0)[2];
        config.sandbox__c = (Pattern.matches('(.*\\.)?cs[0-9]*(-api)?\\..*force.com',hostname));
        
        // Identify if my domain is set
        config.my_domain_enabled__c = hostname.contains('--');
        if (config.my_domain_enabled__c == true){
            config.my_domain__c = hostname.split('--', 0)[0];
        }

        // Set Domain and Survey Site URL
        if (config.sandbox__c == true){
            // Sandbox Org
            config.instance__c = hostname.split('\\.', 0)[1];
            if (config.my_domain_enabled__c == true){
                // My Domain is set
                config.sandbox_name__c = hostname.split('\\.', 0)[0].split('--', 0)[1];
                config.survey_sites_domain__c = sites[0].subdomain + '.' + config.sandbox_name__c + '.' + config.instance__c + '.force.com';
                config.survey_sites_url__c = 'https://' + config.survey_sites_domain__c + '/sugoisurvey/';
                config.sites_username__c = 'sugoisurvey@' + sites[0].subdomain + '.force.com.' + config.sandbox_name__c;
            } else {
                // My Domain is NOT set
                /* Following method to identify sandbox_name is un-reliable. Should be replaced by proper api-call once it's released */
                list<string> divided_username = UserInfo.getUsername().split('\\.',0);
                config.sandbox_name__c = divided_username[divided_username.size() - 1];
                config.survey_sites_domain__c = sites[0].subdomain + '.' + config.sandbox_name__c + '.' + config.instance__c + '.force.com';
                config.survey_sites_url__c = 'https://' + config.survey_sites_domain__c + '/sugoisurvey/';
                config.sites_username__c = 'sugoisurvey@' + config.survey_sites_domain__c;
            }
        } else if(edition == 'Team Edition' || edition == 'Professional Edition' || edition == 'Enterprise Edition' || edition == 'Unlimited Edition'){
            // Production Org
            config.survey_sites_domain__c = sites[0].subdomain + '.force.com';
            config.survey_sites_url__c = 'https://' + sites[0].subdomain + '.secure.force.com/sugoisurvey/';
            config.sites_username__c = 'sugoisurvey@' + config.survey_sites_domain__c;
        } else {
            // Non-Production Org
            config.instance__c = hostname.split('\\.', 0)[1];
            //config.instance__c = hostname.replace('sugoisurvey4','').replace('visual.force.com','').replace('salesforce.com','').replace('.','').replace(sites[0].subdomain + '--', '');
            config.survey_sites_domain__c = sites[0].subdomain + '.' + config.instance__c + '.force.com';
            config.survey_sites_url__c = 'https://' + config.survey_sites_domain__c + '/sugoisurvey/';
            config.sites_username__c = 'sugoisurvey@' + config.survey_sites_domain__c;
        }
        
        upsert config;
    }
    
    
    @remoteAction 
    global static void assign_permission_set(){
        config__c config = config__c.getOrgDefaults();
        
        // Quit if site has not been activated
        if (config.survey_sites_domain__c == null){
            sexception se = new sexception();
            se.setMessage(system.label.sites_not_activated);
            throw se;
        }
        
        // retreive id of user for sites
        string sites_user_id;
        try {
            sites_user_id = [select id from user where username = :config.sites_username__c].id;
        } catch(Exception e) {
            try {
                list<user> site_users = [select id from user where username like 'sugoisurvey@%'];
                if (site_users.size() == 1){
                    sites_user_id = site_users[0].id;
                } else {
                    sexception se = new sexception();
                    se.setMessage(system.label.sites_user_not_found);
                    throw se;
                }
            } catch (Exception ee){
                sexception se = new sexception();
                se.setMessage(system.label.sites_user_not_found);
                throw se;
            }
        }
        
        // retrieve id of permission set for sites
        string sites_permission_set_id;
        try {
            sites_permission_set_id = [select id from permissionSet where name = 'Sugoi_Survey_Sites_for_Any_License' and namespacePrefix = 'sugoisurvey5'].id;
        } catch(Exception e){
            sexception se = new sexception();
            se.setMessage(system.label.sites_permission_set_not_found);
            throw se;
        }
        
        if ([select id from permissionSetAssignment where assigneeId = :sites_user_id and permissionSetId = :sites_permission_set_id].size() == 0){
            permissionSetAssignment psa = new permissionSetAssignment(assigneeId = sites_user_id, permissionSetId = sites_permission_set_id);
            insert psa;
        }
    }
    
    
    @remoteAction 
    global static void start_cron(){
        config__c config = config__c.getOrgDefaults();

        // Quit if app has been initialized.
        if (config.initialized__c == true && config.need_re_initialization__c == false){
            sexception se = new sexception();
            se.setMessage(system.label.already_initialized);
            throw se;
        }

        // Kill existing cron job
        for (cronTrigger ct : [select id from cronTrigger where cronJobDetail.name like 'Cron Trigger v1.13%']){
            system.abortJob(ct.id);
        }
        for (cronTrigger ct : [select id from cronTrigger where cronJobDetail.name like 'Sugoi Survey%']){
            system.abortJob(ct.id);
        }
        
        // Start cron job for universal purpose. As of v4 1.13, chatter_notification.notify_guest_registration_for_pending_guest is the only method to invoke.
        Datetime next = Datetime.now().addMinutes(1);
        string sch = string.valueOf(next.second()) + ' ' + string.valueOf(next.minute()) + ' ' + string.valueOf(next.hour()) + ' ' + string.valueOf(next.day()) + ' ' + string.valueOf(next.month()) + ' ?';
        id cron_trigger_id;
        if (!Test.isRunningTest()){
            cron_trigger_id = system.schedule('Sugoi Survey Cron Trigger v5.0 - ' + sch, sch, new cron_trigger());
        }

        // update config
        config.cron_trigger_id__c = cron_trigger_id;
        config.initialized__c = true;
        config.need_re_initialization__c = false;
        upsert config;
    }
}