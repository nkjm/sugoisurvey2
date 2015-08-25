@isTest
public with sharing class validate_sessionCtl {

    private static testmethod void validate_register_guest(){
        boolean checked = false;

        session__c s = new session__c(name = 'sdfojoiwmflsdf', open_registration__c = true);
        s = sessionCtl.create_session(s);

        guest__c g = new guest__c(session__c = s.id, last_name__c = 'nci9weroerlksf');
        try {
            sessionCtl.register_guest(g, null);
        } catch (Exception e){
            system.assertEquals(system.label.csas_is_not_set, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // database should have rolled back.
        system.assertEquals(0, [select id from guest__c where last_name__c = 'nci9weroerlksf'].size());

        g = new guest__c(session__c = s.id, last_name__c = 'nci9weroerlksf');
        sessionCtl.register_guest(g, new list<custom_survey_answer__c>());
        system.assertEquals(1, [select id from guest__c where last_name__c = 'nci9weroerlksf'].size());

        // add checkbox question for registration and this question is required to answer.
        custom_survey_question__c csq = create_csq_of_checkbox(s.id, true, true);
        csq.for_registration__c = true;
        update csq;
        g = new guest__c(session__c = s.id, last_name__c = 'iweojoasfldkfj');

        // get error since required answer is not included.
        try {
            sessionCtl.register_guest(g, new list<custom_survey_answer__c>());
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + csq.question__c, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // same registration attempt but now the required question is not for registration so it will succeed.
        g = new guest__c(session__c = s.id, last_name__c = 'iweojoasfldkfj');
        csq.for_registration__c = false;
        update csq;
        sessionCtl.register_guest(g, new list<custom_survey_answer__c>());

        // required question is now for registration again. but this time, answer for that question is set so it will succeed.
        csq.for_registration__c = true;
        update csq;
        g = new guest__c(session__c = s.id, last_name__c = 'heojoasdflasdf');
        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        csas.add(new custom_survey_answer__c(custom_survey_option__c = csq.custom_survey_option__r[0].id));
        sessionCtl.register_guest(g, csas);
    }

    private static testmethod void validate_get_session_for_sites(){
        boolean checked = false;

        session__c s = new session__c(name = 'urniadnalds', open__c = false, open_registration__c = false);
        s = sessionCtl.create_session(s);

        // fail. session id is not provided.
        try {
            sessionCtl.get_session_for_sites(null, null);
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // fail. condition is invalid
        try {
            sessionCtl.get_session_for_sites(security.encrypt(s.id), null);
        } catch (Exception e){
            system.assertEquals(system.label.request_invalid, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // fail. survey is closed.
        try {
            sessionCtl.get_session_for_sites(security.encrypt(s.id), 'survey_opening');
        } catch (Exception e){
            system.assertEquals(system.label.survey_is_over, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // fail. registration is closed.
        try {
            sessionCtl.get_session_for_sites(security.encrypt(s.id), 'registration_opening');
        } catch (Exception e){
            system.assertEquals(system.label.registration_is_over, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        s.open__c = true;
        s.open_registration__c = true;
        update s;

        // success. 
        system.assertEquals('urniadnalds', sessionCtl.get_session_for_sites(security.encrypt(s.id), 'survey_opening').name);
        system.assertEquals('urniadnalds', sessionCtl.get_session_for_sites(security.encrypt(s.id), 'registration_opening').name);

        // fail. session not found
        id s_id = s.id;
        delete s;
        try {
            sessionCtl.get_session_for_sites(security.encrypt(s.id), 'survey_opening');
        } catch (Exception e){
            system.assertEquals(system.label.session_not_found, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;
    }

    private static testmethod void validate_create_guest(){
        boolean checked = false;

        session__c s = new session__c(name = 'ljodfoqonefe');
        s = sessionCtl.create_session(s);

        guest__c g = new guest__c(last_name__c = 'dhrgokmefda');
        try {
            sessionCtl.create_guest(g);
        } catch (Exception e){
            system.assertEquals(system.label.required_parameter_is_missing, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // success.
        g.session__c = s.id;
        g = sessionCtl.create_guest(g);
        system.assertEquals('dhrgokmefda', g.last_name__c);

        // success. same lastname but no email so does not duplicate.
        g = new guest__c(last_name__c = 'dhrgokmefda');
        g.session__c = s.id;
        sessionCtl.create_guest(g);

        // success. completely new guest.
        g = new guest__c(last_name__c = 'adsfjjasdfas', email__c = 'adsfjjasdfas@hoge.com');
        g.session__c = s.id;
        sessionCtl.create_guest(g);

        // fail. same email so detect duplication.
        g = new guest__c(last_name__c = 'bjsadflkjlsd', email__c = 'adsfjjasdfas@hoge.com');
        g.session__c = s.id;
        try {
            sessionCtl.create_guest(g);
        } catch (Exception e){
            system.assertEquals(system.label.already_registered, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // success. no lastname and automaticall filled with 'unknown'
        g = new guest__c();
        g.session__c = s.id;
        g = sessionCtl.create_guest(g);
        system.assertEquals(system.label.lastname_unknown, g.last_name__c);
    }

    private static testmethod void validate_save_guest_as_contact(){
        session__c s = new session__c(name = 'dnewiusdfl');
        sessionCtl.create_session(s);

        boolean checked = false;
        try {
            sessionCtl.save_guest_as_contact(null);
        } catch (Exception e){
            system.assertEquals(system.label.required_parameter_is_missing, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        guest__c g = new guest__c(session__c = s.id, last_name__c = 'sjovnwerlkfd');
        insert g;
        id deleted_guest_id = g.id;
        delete g;
        try {
            sessionCtl.save_guest_as_contact(deleted_guest_id);
        } catch (Exception e){
            system.assertEquals(system.label.guest_not_found, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        contact c = new contact(lastname = 'guerljaldf');
        insert c;
        g = new guest__c(session__c = s.id, last_name__c = 'saldfjasdf', contact__c = c.id);
        insert g;
        try {
            sessionCtl.save_guest_as_contact(g.id);
        } catch (Exception e){
            system.assertEquals(system.label.contact_already_exist, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // New Account will be created.
        // Newly created Contact will be linked to the new Account.
        g = new guest__c(session__c = s.id, last_name__c = 'dfusfdlsdf', company__c = 'iwefhondglksljw');
        insert g;
        sessionCtl.save_guest_as_contact(g.id);
        list<account> accts = [select id from account where name = 'iwefhondglksljw'];
        system.assertEquals(1, accts.size());
        g = [select id, contact__c from guest__c where id = :g.id];
        system.assertNotEquals(null, g.contact__c);
        list<contact> conts = [select id from contact where id = :g.contact__c];
        system.assertEquals(1, conts.size());

        // 1 Account found.
        // Newly created Contact will be linked to this existing Account.
        g = new guest__c(session__c = s.id, last_name__c = 'iiuurndfkmf', company__c = 'iwefhondglksljw');
        insert g;
        sessionCtl.save_guest_as_contact(g.id);
        accts = [select id from account where name = 'iwefhondglksljw'];
        system.assertEquals(1, accts.size());
        g = [select id, contact__c from guest__c where id = :g.id];
        system.assertNotEquals(null, g.contact__c);
        conts = [select id, accountId from contact where id = :g.contact__c];
        system.assertEquals(1, conts.size());
        system.assertEquals(accts[0].id, conts[0].accountId);
        
        // Multiple Accounts found.
        // Newly create Contact will not be linked to any Account.
        account a = new account(name = 'iwefhondglksljw');
        insert a;
        g = new guest__c(session__c = s.id, last_name__c = 'asdfnldfffff', company__c = 'iwefhondglksljw');
        insert g;
        sessionCtl.save_guest_as_contact(g.id);
        accts = [select id from account where name = 'iwefhondglksljw'];
        system.assertEquals(2, accts.size());
        g = [select id, contact__c from guest__c where id = :g.id];
        system.assertNotEquals(null, g.contact__c);
        conts = [select id, accountId from contact where id = :g.contact__c];
        system.assertEquals(1, conts.size());
        system.assertEquals(null, conts[0].accountId);
    }

    private static testmethod void validate_get_free_answers_of_checkbox(){
        session__c s = new session__c(name = 'dnewiusdfl', who_can_submit_survey__c = 'Anyone');
        insert s;

        custom_survey_question__c csq = create_csq_of_checkbox(s.id);
        id cso_free_id;
        for (custom_survey_option__c cso : csq.custom_survey_option__r){
            if (cso.enable_free_form__c){
                cso_free_id = cso.id;
            }
        }

        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        csas.add(new custom_survey_answer__c(custom_survey_option__c = cso_free_id, free_form__c = 'ibaefroofmoaerflasdfaf'));

        sessionCtl.submit_survey(s.id, csas, null, false);

        system.assertEquals(1, sessionCtl.get_free_answers(csq.id).size());
        system.assertEquals('ibaefroofmoaerflasdfaf', sessionCtl.get_free_answers(csq.id)[0].free_form__c);
    }

    private static testmethod void validate_get_answers_by_guest(){
        boolean checked = false;
        session__c s = new session__c(name = 'lsjadflsdf', who_can_submit_survey__c = 'Anyone');
        insert s;

        custom_survey_question__c csq_of_checkbox = create_csq_of_checkbox(s.id);

        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        csas.add(new custom_survey_answer__c(session__c = s.id, custom_survey_option__c = csq_of_checkbox.custom_survey_option__r[0].id));
        sessionCtl.submit_survey(s.id, csas, null, false);

        // Required Parameter is missing
        try {
            sessionCtl.get_answers_by_guest(null);
        } catch (Exception e){
            system.assertEquals(system.label.required_parameter_is_missing, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        system.assertEquals(1, sessionCtl.get_answers_by_guest([select id from guest__c where session__c = :s.id].id).size());
    }

    private static testmethod void validate_get_guests_by_condition(){
        boolean checked = false;
        session__c s = new session__c(name = 'lsjadflsdf', who_can_submit_survey__c = 'Anyone');
        insert s;

        custom_survey_question__c csq_of_checkbox = create_csq_of_checkbox(s.id);

        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        csas.add(new custom_survey_answer__c(session__c = s.id, custom_survey_option__c = csq_of_checkbox.custom_survey_option__r[0].id));
        sessionCtl.submit_survey(s.id, csas, null, false);

        // Required Parameter is missing
        try {
            sessionCtl.get_guests_by_condition(null, null, null);
        } catch (Exception e){
            system.assertEquals(system.label.required_parameter_is_missing, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;
        
        // Search By cso_id
        system.assertEquals(1, sessionCtl.get_guests_by_condition(s.id, 'cso_id', csq_of_checkbox.custom_survey_option__r[0].id).size());
        system.assertEquals(0, sessionCtl.get_guests_by_condition(s.id, 'cso_id', csq_of_checkbox.custom_survey_option__r[1].id).size());

        // Search By guest_id
        system.assertEquals(1, sessionCtl.get_guests_by_condition(s.id, 'guest_id', [select id from guest__c where session__c = :s.id].id).size());

        custom_survey_question__c csq_of_number = create_csq_of_number(s.id);

        csas = new list<custom_survey_answer__c>();
        csas.add(new custom_survey_answer__c(session__c = s.id, free_form_of_number__c = 2, custom_survey_option__c = csq_of_number.custom_survey_option__r[0].id));
        sessionCtl.submit_survey(s.id, csas, null, false);

        // Search By range
        system.assertEquals(1, sessionCtl.get_guests_by_condition(s.id, 'range', '1-2').size());
        system.assertEquals(0, sessionCtl.get_guests_by_condition(s.id, 'range', '3-4').size());
    }

    private static testmethod void validate_submit_survey_with_sguest_id(){
        boolean checked = false;
        session__c session = new session__c(name = 'id9rjnsfojwer', open_registration__c = true, who_can_submit_survey__c = 'Registered Guests Only');
        sessionCtl.create_session(session);

        // create csq of survey type = checkbox and required = true;
        custom_survey_question__c csq_of_checkbox = create_csq_of_checkbox(session.id, true, true);

        guest__c guest = new guest__c(last_name__c = 'jafokasflkjlasdf', email__c = 'jafokasflkjlasdf@hoge.com', session__c = session.id);
        guest = sessionCtl.create_guest(guest);

        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();

        // get error since required answer(checkbox) is not set.
        try {
            sessionCtl.submit_survey(session.id, csas, security.encrypt(guest.id), false);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + csq_of_checkbox.question__c, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;
        
        csas.add(new custom_survey_answer__c(custom_survey_option__c = csq_of_checkbox.custom_survey_option__r[0].id));

        // get error since required answer(guest) is not set.
        try {
            sessionCtl.submit_survey(session.id, csas, null, false);
        } catch (Exception e){
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // success.
        sessionCtl.submit_survey(session.id, csas, security.encrypt(guest.id), false);

        list<custom_survey_answer__c> submitted_csas = [select id, guest__c from custom_survey_answer__c where session__c = :session.id];
        system.assertEquals(1, submitted_csas.size());

        // check if submitted answer is owned by the guest.
        system.assertEquals(guest.id, submitted_csas[0].guest__c);
        guest = [select id, status__c from guest__c where id = :guest.id];

        // check if guest status has been changed to submitted.
        system.assertEquals('submitted', guest.status__c);

        id deleted_guest_id = guest.id;
        delete guest;
        csas = new list<custom_survey_answer__c>();
        csas.add(new custom_survey_answer__c(custom_survey_option__c = csq_of_checkbox.custom_survey_option__r[0].id));

        // got error of guest not found since guest has been deleted.
        try {
            sessionCtl.submit_survey(session.id, csas, security.encrypt(deleted_guest_id), false);
        } catch(Exception e){
            system.assertEquals(system.label.guest_not_found, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;
    }

    private static testmethod void validate_submit_survey_of_survey_type_guest(){
        boolean checked = false;

        session__c session = new session__c(name = 'lsjaaaadfasdf', who_can_submit_survey__c = 'Anyone');
        sessionCtl.create_session(session);

        // create csq of survey type = guest and required = true;
        custom_survey_question__c csq = create_csq_of_guest(session.id, true);

        // null for session id
        try {
            sessionCtl.submit_survey(null, new list<custom_survey_answer__c>(), null, false);
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // required answer is not set
        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        for (custom_survey_option__c cso : csq.custom_survey_option__r){
            if (cso.required__c == false){
                csas.add(new custom_survey_answer__c(custom_survey_option__c = cso.id));
            }
        }
        try {
            sessionCtl.submit_survey(session.id, csas, null, false);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + csq.question__c, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // required answer is set but empty
        csas = new list<custom_survey_answer__c>();
        for (custom_survey_option__c cso : csq.custom_survey_option__r){
            if (cso.required__c == true){
                csas.add(new custom_survey_answer__c(custom_survey_option__c = cso.id));
            }
        }
        try {
            sessionCtl.submit_survey(session.id, csas, null, false);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + csq.question__c, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // required answer is set and filled
        csas = new list<custom_survey_answer__c>();
        for (custom_survey_option__c cso : csq.custom_survey_option__r){
            if (cso.required__c == true){
                csas.add(new custom_survey_answer__c(custom_survey_option__c = cso.id, free_form__c = 'hoge@hoge.com'));
            }
        }
        sessionCtl.submit_survey(session.id, csas, null, false);
    }


    private static testmethod void validate_submit_survey_of_survey_type_checkbox(){
        boolean checked = false;

        session__c session = new session__c(name = 'hugybfiwff', who_can_submit_survey__c = 'Anyone');
        sessionCtl.create_session(session);

        // create csq of survey type = checkbox and required = true;
        custom_survey_question__c csq = create_csq_of_checkbox(session.id, true, true);
        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        // required answer for newly added question is not set.
        try {
            sessionCtl.submit_survey(session.id, csas, null, false);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + csq.question__c, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // all required answer is set.
        csas.add(new custom_survey_answer__c(custom_survey_option__c = csq.custom_survey_option__r[0].id));
        sessionCtl.submit_survey(session.id, csas, null, false);
    }

    private static testmethod void validate_submit_survey_of_survey_type_free(){
        boolean checked = false;

        session__c session = new session__c(name = 'sdfiwff', who_can_submit_survey__c = 'Anyone');
        sessionCtl.create_session(session);

        // create csq of survey type = checkbox and required = true;
        custom_survey_question__c csq = create_csq_of_free(session.id, true);
        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        // required answer is not set.
        try {
            sessionCtl.submit_survey(session.id, csas, null, false);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + csq.question__c, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        csas.add(new custom_survey_answer__c(custom_survey_option__c = csq.custom_survey_option__r[0].id));
        // required answer is set but empty
        try {
            sessionCtl.submit_survey(session.id, csas, null, false);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + csq.question__c, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // all required answer is set.
        csas[0].free_form__c = 'kljsdfasdfas';
        sessionCtl.submit_survey(session.id, csas, null, false);
    }

    private static testmethod void validate_submit_survey_of_survey_type_number(){
        boolean checked = false;

        session__c session = new session__c(name = 'sdfiwff', who_can_submit_survey__c = 'Anyone');
        sessionCtl.create_session(session);

        // create csq of survey type = checkbox and required = true;
        custom_survey_question__c csq = create_csq_of_number(session.id, true);
        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        // required answer is not set.
        try {
            sessionCtl.submit_survey(session.id, csas, null, false);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + csq.question__c, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        csas.add(new custom_survey_answer__c(custom_survey_option__c = csq.custom_survey_option__r[0].id));
        // required answer is set but empty
        try {
            sessionCtl.submit_survey(session.id, csas, null, false);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + csq.question__c, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // all required answer is set.
        csas[0].free_form_of_number__c = 25;
        sessionCtl.submit_survey(session.id, csas, null, false);
    }

    private static testmethod void validate_submit_survey_of_survey_type_rating(){
        boolean checked = false;

        session__c session = new session__c(name = 'hugybfiwff', who_can_submit_survey__c = 'Anyone');
        sessionCtl.create_session(session);

        // create csq of survey type = checkbox and required = true;
        custom_survey_question__c csq = create_csq_of_rating(session.id, true);
        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        // required answer for newly added question is not set.
        try {
            sessionCtl.submit_survey(session.id, csas, null, false);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + csq.question__c, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        // all required answer is set.
        csas.add(new custom_survey_answer__c(custom_survey_option__c = csq.custom_survey_option__r[0].id));
        sessionCtl.submit_survey(session.id, csas, null, false);
    }

    private static testmethod void validate_submit_survey_of_entitlement_anyone(){

        //// 
        //// Does not provide email. Anonymous guest will be created.
        ////
        session__c session = new session__c(name = 'vdsfgwff', who_can_submit_survey__c = 'Anyone');
        sessionCtl.create_session(session);

        custom_survey_question__c csq = create_csq_of_guest(session.id, false);
        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        sessionCtl.submit_survey(session.id, csas, null, false);
        list<guest__c> guests = [select id, last_name__c from guest__c where session__c = :session.id];
        system.assertEquals(1, guests.size());
        system.assertEquals(system.label.unregistered_guest, guests[0].last_name__c);

        delete session;


        ////
        //// Provide email but not registered. A guest will be created with provided email and lastname.
        ////
        session = new session__c(name = 'vdsfgwff', who_can_submit_survey__c = 'Anyone');
        sessionCtl.create_session(session);

        csq = create_csq_of_guest(session.id, false);

        for (custom_survey_option__c cso : csq.custom_survey_option__r){
            if (cso.option__c == 'sugoisurvey5__Email__c'){
                csas.add(new custom_survey_answer__c(session__c = session.id, custom_survey_option__c = cso.id, free_form__c = 'asddfaf@hoge.com'));
            }
            if (cso.option__c == 'sugoisurvey5__Last_Name__c'){
                csas.add(new custom_survey_answer__c(session__c = session.id, custom_survey_option__c = cso.id, free_form__c = 'osdfllasdf'));
            }
        }
        sessionCtl.submit_survey(session.id, csas, null, false);
        guests = [select id, last_name__c, email__c from guest__c where session__c = :session.id];
        system.assertEquals(1, guests.size());
        system.assertEquals('osdfllasdf', guests[0].last_name__c);
        system.assertEquals('asddfaf@hoge.com', guests[0].email__c);

        delete session;


        ////
        //// Provide email and registered. No new guest will be created but updated with provided lastname.
        ////
        session = new session__c(name = 'vdsfgwff', who_can_submit_survey__c = 'Anyone');
        sessionCtl.create_session(session);

        csq = create_csq_of_guest(session.id, false);

        guest__c guest = new guest__c(session__c = session.id, last_name__c = 'asdfaafsd', email__c = 'voaedf@hoge.com');
        insert guest;

        csas = new list<custom_survey_answer__c>();
        for (custom_survey_option__c cso : csq.custom_survey_option__r){
            if (cso.option__c == 'sugoisurvey5__Email__c'){
                csas.add(new custom_survey_answer__c(session__c = session.id, custom_survey_option__c = cso.id, free_form__c = 'voaedf@hoge.com'));
            }
            if (cso.option__c == 'sugoisurvey5__Last_Name__c'){
                csas.add(new custom_survey_answer__c(session__c = session.id, custom_survey_option__c = cso.id, free_form__c = 'osdfllasdf'));
            }
        }
        sessionCtl.submit_survey(session.id, csas, null, false);
        guests = [select id, last_name__c, email__c from guest__c where session__c = :session.id];
        system.assertEquals(1, guests.size());
        system.assertEquals('osdfllasdf', guests[0].last_name__c);
        system.assertEquals('voaedf@hoge.com', guests[0].email__c);
    }

    private static testmethod void validate_submit_survey_of_entitlement_require_email(){
        boolean checked = false;

        //// 
        //// Does not provide email. Error.
        ////
        session__c session = new session__c(name = 'vdsfgwff', who_can_submit_survey__c = 'Require Email');
        sessionCtl.create_session(session);

        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        try {
            sessionCtl.submit_survey(session.id, csas, null, false);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + system.label.pls_enter_guest_info, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        delete session;


        ////
        //// Provide email but not registered. Anonymous guest will be created with provided email.
        ////
        session = new session__c(name = 'vdsfgwff', who_can_submit_survey__c = 'Require Email');
        sessionCtl.create_session(session);

        for (custom_survey_option__c cso : [select id, (select option__c from custom_survey_option__r) from custom_survey_question__c where session__c = :session.id][0].custom_survey_option__r){
            if (cso.option__c == 'sugoisurvey5__Email__c'){
                csas.add(new custom_survey_answer__c(session__c = session.id, custom_survey_option__c = cso.id, free_form__c = 'asddfaf@hoge.com'));
            }
        }
        sessionCtl.submit_survey(session.id, csas, null, false);
        list<guest__c> guests = [select id, last_name__c, email__c from guest__c where session__c = :session.id];
        system.assertEquals(1, guests.size());
        system.assertEquals(system.label.unregistered_guest, guests[0].last_name__c);
        system.assertEquals('asddfaf@hoge.com', guests[0].email__c);

        delete session;


        ////
        //// Provide email and registered. No new guest will be created but updated with provided lastname.
        ////
        session = new session__c(name = 'vdsfgwff', who_can_submit_survey__c = 'Require Email');
        sessionCtl.create_session(session);
        delete [select id from custom_survey_question__c where session__c = :session.id];
        custom_survey_question__c csq = create_csq_of_guest(session.id, true);

        guest__c guest = new guest__c(session__c = session.id, last_name__c = 'asdfaafsd', email__c = 'voaedf@hoge.com');
        insert guest;

        csas = new list<custom_survey_answer__c>();
        for (custom_survey_option__c cso : csq.custom_survey_option__r){
            if (cso.option__c == 'sugoisurvey5__Email__c'){
                csas.add(new custom_survey_answer__c(session__c = session.id, custom_survey_option__c = cso.id, free_form__c = 'voaedf@hoge.com'));
            }
            if (cso.option__c == 'sugoisurvey5__Last_Name__c'){
                csas.add(new custom_survey_answer__c(session__c = session.id, custom_survey_option__c = cso.id, free_form__c = 'osdfllasdf'));
            }
        }
        sessionCtl.submit_survey(session.id, csas, null, false);
        guests = [select id, last_name__c, email__c from guest__c where session__c = :session.id];
        system.assertEquals(1, guests.size());
        system.assertEquals('osdfllasdf', guests[0].last_name__c);
        system.assertEquals('voaedf@hoge.com', guests[0].email__c);
    }

    private static testmethod void validate_submit_survey_of_entitlement_registered_guests_only(){
        boolean checked = false;

        //// 
        //// Does not provide email. Error.
        ////
        session__c session = new session__c(name = 'vdsfgwff', who_can_submit_survey__c = 'Registered Guests Only');
        sessionCtl.create_session(session);

        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        try {
            sessionCtl.submit_survey(session.id, csas, null, false);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + system.label.pls_enter_guest_info, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;

        delete session;


        ////
        //// Provide email but not registered. Error.
        ////
        session = new session__c(name = 'vdsfgwff', who_can_submit_survey__c = 'Registered Guests Only');
        sessionCtl.create_session(session);

        for (custom_survey_option__c cso : [select id, (select option__c from custom_survey_option__r) from custom_survey_question__c where session__c = :session.id][0].custom_survey_option__r){
            if (cso.option__c == 'sugoisurvey5__Email__c'){
                csas.add(new custom_survey_answer__c(session__c = session.id, custom_survey_option__c = cso.id, free_form__c = 'asddfaf@hoge.com'));
            }
        }
        try {
            sessionCtl.submit_survey(session.id, csas, null, false);   
        } catch (Exception e){
            system.assertEquals(system.label.email_not_registered, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
        checked = false;
        
        delete session;


        ////
        //// Provide email and registered. No new guest will be created but updated with provided lastname.
        ////
        session = new session__c(name = 'vdsfgwff', who_can_submit_survey__c = 'Registered Guests Only');
        sessionCtl.create_session(session);
        delete [select id from custom_survey_question__c where session__c = :session.id];
        custom_survey_question__c csq = create_csq_of_guest(session.id, true);

        guest__c guest = new guest__c(session__c = session.id, last_name__c = 'asdfaafsd', email__c = 'voaedf@hoge.com');
        insert guest;

        csas = new list<custom_survey_answer__c>();
        for (custom_survey_option__c cso : csq.custom_survey_option__r){
            if (cso.option__c == 'sugoisurvey5__Email__c'){
                csas.add(new custom_survey_answer__c(session__c = session.id, custom_survey_option__c = cso.id, free_form__c = 'voaedf@hoge.com'));
            }
            if (cso.option__c == 'sugoisurvey5__Last_Name__c'){
                csas.add(new custom_survey_answer__c(session__c = session.id, custom_survey_option__c = cso.id, free_form__c = 'osdfllasdf'));
            }
        }
        sessionCtl.submit_survey(session.id, csas, null, false);
        list<guest__c> guests = [select id, last_name__c, email__c from guest__c where session__c = :session.id];
        system.assertEquals(1, guests.size());
        system.assertEquals('osdfllasdf', guests[0].last_name__c);
        system.assertEquals('voaedf@hoge.com', guests[0].email__c);
    }

    private static testmethod void validate_submit_survey_duplicated(){
        boolean checked = false;

        session__c session = new session__c(name = 'vdsfgwff', who_can_submit_survey__c = 'Anyone');
        sessionCtl.create_session(session);

        custom_survey_question__c csq = create_csq_of_guest(session.id, false);
        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();

        for (custom_survey_option__c cso : csq.custom_survey_option__r){
            if (cso.option__c == 'sugoisurvey5__Email__c'){
                csas.add(new custom_survey_answer__c(session__c = session.id, custom_survey_option__c = cso.id, free_form__c = 'asddfaf@hoge.com'));
            }
        }

        sessionCtl.submit_survey(session.id, csas, null, false);
        list<guest__c> guests = [select id, last_name__c from guest__c where session__c = :session.id];
        system.assertEquals(1, guests.size());
        system.assertEquals(system.label.unregistered_guest, guests[0].last_name__c);

        csas = new list<custom_survey_answer__c>();
        for (custom_survey_option__c cso : csq.custom_survey_option__r){
            if (cso.option__c == 'sugoisurvey5__Email__c'){
                csas.add(new custom_survey_answer__c(session__c = session.id, custom_survey_option__c = cso.id, free_form__c = 'asddfaf@hoge.com'));
            }
        }

        try {
            sessionCtl.submit_survey(session.id, csas, null, false);
        } catch (Exception e){
            system.assertEquals(system.label.already_submitted, e.getMessage());
            checked = true;
        }
        system.assertEquals(true, checked);
    }

    private static testmethod void validate_create_session(){
        session__c session;
        list<custom_survey_question__c> csqs = new list<custom_survey_question__c>();

        // Create session setting who_can_submit_survey__c to 'Anyone'. No CSQ will be created.
        session = new session__c(name = 'ldfolkdglkjsadf', date__c = Date.today(), who_can_submit_survey__c = 'Anyone');
        sessionCtl.create_session(session);
        csqs = [select id, survey_type__c, (select id, option__c from custom_survey_option__r) from custom_survey_question__c where session__c = :session.id];
        system.assertEquals(0, csqs.size());

        // Create session setting who_can_submit_survey__c to 'Require Email'. CSQ of guest will be created.
        session = new session__c(name = 'ldfolkdglkjsadf', date__c = Date.today(), who_can_submit_survey__c = 'Require Email');
        sessionCtl.create_session(session);
        csqs = [select id, survey_type__c, (select id, option__c from custom_survey_option__r) from custom_survey_question__c where session__c = :session.id];
        system.assertEquals(1, csqs.size());
        system.assertEquals('guest', csqs[0].survey_type__c);
        system.assertEquals(1, csqs[0].custom_survey_option__r.size());
        system.assertEquals('sugoisurvey5__Email__c', csqs[0].custom_survey_option__r[0].option__c);
    }

    private static testmethod void validate_update_session(){
        session__c session;
        list<custom_survey_question__c> csqs;

        session = new session__c(name = 'ldfolkdglkjsadf', date__c = Date.today(), who_can_submit_survey__c = 'Anyone');
        sessionCtl.create_session(session);

        // Update session.name. session.name will be updated.
        session.name = 'ncuwahflkjadf';
        sessionCtl.update_session(session);
        system.assertEquals('ncuwahflkjadf', [select name from session__c where id = :session.id][0].name);

        // Set date__c to null. date__c will be null.
        session.date__c = null;
        sessionCtl.update_session(session);
        system.assertEquals(null, [select date__c from session__c where id = :session.id][0].date__c);

        // Change who_can_submit_survey__c from "Anyone" to "Require Email". CSQ of guest will be added.
        session.who_can_submit_survey__c = 'Require Email';
        sessionCtl.update_session(session);
        csqs = [select id, survey_type__c, (select id, option__c from custom_survey_option__r) from custom_survey_question__c where session__c = :session.id];
        system.assertEquals(1, csqs.size());
        system.assertEquals('guest', csqs[0].survey_type__c);
        system.assertEquals(1, csqs[0].custom_survey_option__r.size());
        system.assertEquals('sugoisurvey5__Email__c', csqs[0].custom_survey_option__r[0].option__c);

        // Delete CSO and update session. CSO of email will be added.
        delete csqs[0].custom_survey_option__r[0];
        sessionCtl.update_session(session);
        csqs = [select id, survey_type__c, (select id, option__c from custom_survey_option__r) from custom_survey_question__c where session__c = :session.id];
        system.assertEquals(1, csqs.size());
        system.assertEquals('guest', csqs[0].survey_type__c);
        system.assertEquals(1, csqs[0].custom_survey_option__r.size());
        system.assertEquals('sugoisurvey5__Email__c', csqs[0].custom_survey_option__r[0].option__c);

        // Delete CSQ and set session.who_can_submit_survey__c to "Anyone". CSQ will not be added.
        delete csqs;
        session.who_can_submit_survey__c = 'Anyone';
        sessionCtl.update_session(session);
        csqs = [select id, survey_type__c, (select id, option__c from custom_survey_option__r) from custom_survey_question__c where session__c = :session.id];
        system.assertEquals(0, csqs.size());
    }
    
    private static testmethod void validate_get_session(){
        session__c session;
        session = new session__c(name = 'wpoeiru', open__c = true);
        insert session;

        /*
        Condition
        - session_id => null
        - open__c => true
        */
        try {
        	sessionCtl.get_session(null);
    	} catch (Exception e){
    		system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
    	}
        
        /*
        Condition
        - session_id => set(exists)
        - open__c => true
        */
        system.assertEquals('wpoeiru', sessionCtl.get_session(session.id).name);

        /*
        Condition
        - session_id => set(exists)
        - open__c => false
        */
        session.open__c = false;
        update session;
        system.assertEquals('wpoeiru', sessionCtl.get_session(session.id).name);
        
        /*
        Condition
        - session_id => set(not exist)
        - open__c => n/a
        */
        delete session;
        try {
            sessionCtl.get_session(session.id);
        } catch (QueryException qe){
            system.assertEquals('List has no rows for assignment to SObject', qe.getMessage());
        }
    }

    private static testmethod void validate_clone_session(){
    	session__c session;
    	custom_survey_question__c csq;

        try {
            sessionCtl.clone_session(null);
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
        }
        
        session = new session__c(name = 'mcbdyrufjdbdjfjdbdjfkdn', who_can_submit_survey__c = 'Anyone');
        sessionCtl.create_session(session);
        csq = create_csq_of_checkbox(session.id);

        id cloned_session_id = sessionCtl.clone_session(session.id);
        system.assertEquals(1, [select id from session__c where name = 'mcbdyrufjdbdjfjdbdjfkdn - COPY'].size());
        system.assertEquals(1, [select id from custom_survey_question__c where session__c = :cloned_session_id].size());
        system.assertEquals(csq.custom_survey_option__r.size(), [select id from custom_survey_option__c where session__c = :cloned_session_id].size());
    
        // check if brand logo is cloned and brand_logo_id__c is updated
        Attachment brand_logo = new Attachment(Name = 'osdfkjlsdfa', Body = Blob.valueOf('ajsdofjsadfaf'), ParentId = session.id);
        insert brand_logo;
        session.Brand_Logo_Id__c = brand_logo.Id;
        update session;
        cloned_session_id = sessionCtl.clone_session(session.id);
        session__c cloned_session = [select Brand_Logo_Id__c from session__c where Id = :cloned_session_id][0];
        system.assertNotEquals(brand_logo.Id, cloned_session.Brand_Logo_Id__c);
        system.assertEquals(cloned_session.Brand_Logo_Id__c, [select Id from Attachment where ParentId = :cloned_session_id][0].Id);
    }
    
    private static testmethod void validate_sort_questions(){
        session__c s = new session__c(name = 'curnfivdnbnef', who_can_submit_survey__c = 'Anyone');
        insert s;
        
        custom_survey_question__c csq = new custom_survey_question__c(session__c = s.id, question__c = '#1');
        insert csq;
        
        list<id> question_ids = new list<id>();
        question_ids.add(csq.id);

        // session id is null       
        try {
            sessionCtl.sort_questions(null, question_ids);
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
        }
        
        // requested # of question < 2
        try {
            sessionCtl.sort_questions(s.id, question_ids);
        } catch (Exception e){
            system.assertEquals(system.label.there_are_not_enough_number_of_question_to_sort, e.getMessage());
        }
        
        // re-order and sort_order__c in 2 questions are updated
        csq = new custom_survey_question__c(session__c = s.id, question__c = '#2');
        insert csq;
        question_ids.add(csq.id);
        sessionCtl.sort_questions(s.id, question_ids);
        system.assertEquals(1, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#1'].sort_order__c);
        system.assertEquals(2, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#2'].sort_order__c);

        // reverse the order
        list<id> question_ids_reversed = question_ids.clone();
        question_ids_reversed[0] = question_ids[1];
        question_ids_reversed[1] = question_ids[0];
        sessionCtl.sort_questions(s.id, question_ids_reversed);
        system.assertEquals(2, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#1'].sort_order__c);
        system.assertEquals(1, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#2'].sort_order__c);
        
        // # of question in database < 2
        delete csq;
        try {
            sessionCtl.sort_questions(s.id, question_ids_reversed);
        } catch (Exception e){
            system.assertEquals(system.label.there_are_not_enough_number_of_question_to_sort, e.getMessage());
        }

        // # of requested question < database
        csq = new custom_survey_question__c(session__c = s.id, question__c = '#2');
        insert csq;
        csq = new custom_survey_question__c(session__c = s.id, question__c = '#3');
        insert csq;
        list<custom_survey_question__c> csqs = [select id from custom_survey_question__c where session__c = :s.id];
        question_ids = new list<id>();
        for (custom_survey_question__c csq_qoiweuyr : csqs){
            question_ids.add(csq_qoiweuyr.id);
        }
        csq = new custom_survey_question__c(session__c = s.id, question__c = '#4');
        insert csq;
        try {
            sessionCtl.sort_questions(s.id, question_ids);
        } catch (Exception e){
            system.assertEquals(system.label.requested_number_of_question_is_not_valid, e.getMessage());
        }

        // # of requested question > database
        csqs = [select id from custom_survey_question__c where session__c = :s.id];
        question_ids = new list<id>();
        for (custom_survey_question__c csq_ueryyruu : csqs){
            question_ids.add(csq_ueryyruu.id);
        }
        question_ids[0] = s.id;
        try {
            sessionCtl.sort_questions(s.id, question_ids);
        } catch (Exception e){
            system.assertEquals(system.label.specified_question_not_found, e.getMessage());
        }
    }

    private static testmethod void validate_create_question(){
    	session__c s;
        custom_survey_question__c csq = new custom_survey_question__c();
        list<custom_survey_option__c> csos = new list<custom_survey_option__c>();
        
        try {
            sessionCtl.create_question(csq, csos);
        } catch (Exception e){     
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());       
        }

        // non-exist sesssion
        s = new session__c(name = 'lkunoiwladkfad');
        insert s;
        delete s;
        csq.session__c = s.id;
        try {
            sessionCtl.create_question(csq, csos);
        } catch (Exception e){
            system.assertEquals(system.label.specified_session_does_not_exist, e.getMessage());
        }

        // empty question
        s = new session__c(name = 'lkunoiwladkfad');
        insert s;
        csq.session__c = s.id;
        try {
            sessionCtl.create_question(csq, csos);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_question, e.getMessage());
        }
    }

    private static testmethod void validate_create_question_of_choice(){
    	session__c s = new session__c(name = 'lksjdfljsdl');
        insert s;
        custom_survey_question__c csq = create_csq_of_checkbox(s.id);
        system.assertEquals(1, [select id from custom_survey_question__c where session__c = :s.id AND id = :csq.id].size());
        system.assertEquals(3, [select id from custom_survey_option__c where session__c = :s.id AND custom_survey_question__c = :csq.id].size());
    }

    private static testmethod void validate_create_question_of_free(){
        session__c s = new session__c(name = 'lksjdfljsdl');
        insert s;
        custom_survey_question__c csq = create_csq_of_free(s.id);
        system.assertEquals(1, [select id from custom_survey_question__c where session__c = :s.id AND id = :csq.id].size());
        system.assertEquals(1, [select id from custom_survey_option__c where session__c = :s.id AND custom_survey_question__c = :csq.id].size());
    }

    private static testmethod void validate_create_question_of_rating(){
    	session__c s = new session__c(name = 'lksjdfljsdl');
        insert s;
        custom_survey_question__c csq = new custom_survey_question__c();
        csq.session__c = s.id;
        csq.question__c = 'wqoeiurpqowiuer';
        csq.survey_type__c = 'rating';

        // invalid rating_steps__c
        csq.rating_steps__c = 0;
        try {
        	sessionCtl.create_question(csq, null);
    	} catch (Exception e){
    		system.assertEquals(system.label.rating_steps_is_invalid, e.getMessage());
    	}

        csq.rating_steps__c = 11;
        try {
        	sessionCtl.create_question(csq, null);
    	} catch (Exception e){
    		system.assertEquals(system.label.rating_steps_is_invalid, e.getMessage());
    	}

    	// valid rating steps
    	csq.rating_steps__c = 3;
        id csq_id = sessionCtl.create_question(csq, null);
        system.assertEquals(1, [select id from custom_survey_question__c where session__c = :s.id AND id = :csq_id].size());
        system.assertEquals(3, [select id from custom_survey_option__c where session__c = :s.id AND custom_survey_question__c = :csq_id].size());
    }

    private static testmethod void validate_create_question_of_number(){
        session__c s = new session__c(name = 'lksjdfljsdl');
        insert s;
        custom_survey_question__c csq = create_csq_of_number(s.id);
        system.assertEquals(1, [select id from custom_survey_question__c where session__c = :s.id AND id = :csq.id].size());
        system.assertEquals(1, [select id from custom_survey_option__c where session__c = :s.id AND custom_survey_question__c = :csq.id].size());
    }

    private static testmethod void validate_create_question_of_guest(){
        session__c s = new session__c(name = 'lksjdfljsdl', who_can_submit_survey__c = 'Anyone');
        insert s;
        
        custom_survey_question__c csq = create_csq_of_guest(s.id, false);

        system.assertEquals(1, [select id from custom_survey_question__c where session__c = :s.id AND id = :csq.id].size());
        system.assertEquals(4, [select id from custom_survey_option__c where session__c = :s.id AND custom_survey_question__c = :csq.id].size());

        try {
        	create_csq_of_guest(s.id, false);
        } catch (Exception e){
        	system.assertEquals(system.label.guest_question_already_exists, e.getMessage());
        }
    }

    private static testmethod void validate_update_question(){
    	boolean error_found = false;
    	session__c s;
    	custom_survey_question__c csq;

    	// csq.session__c is empty
        try {
            sessionCtl.update_question(new custom_survey_question__c(), new list<custom_survey_option__c>());
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
            error_found = true;
        }
        system.assertEquals(true, error_found);
        error_found = false;
        
        
        s = new session__c(name = 'weifosdfodvm');
        insert s;
        csq = create_csq_of_checkbox(s.id);
        
        // csq.id is not set
        try {
            sessionCtl.update_question(new custom_survey_question__c(session__c = s.id), new list<custom_survey_option__c>());
        } catch (Exception e){
            system.assertEquals(system.label.survey_id_is_not_set, e.getMessage());
        	error_found = true;
        }
        system.assertEquals(true, error_found);
        error_found = false;
        
        // csq.question__c is emply
        try {
            sessionCtl.update_question(new custom_survey_question__c(session__c = s.id, id = csq.id), new list<custom_survey_option__c>());
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_question, e.getMessage());
        	error_found = true;
        }
        system.assertEquals(true, error_found);
        error_found = false;

        delete s;
        
        // session does not exist
        try {
            sessionCtl.update_question(new custom_survey_question__c(session__c = s.id, id = csq.id, question__c = 'question for validate'), new list<custom_survey_option__c>());
        } catch (Exception e){
            system.assertEquals(system.label.specified_session_does_not_exist, e.getMessage());
        	error_found = true;
        }
        system.assertEquals(true, error_found);
        error_found = false;

        s = new session__c(name = 'weifosdfodvm');
        insert s;

        // question does not exist
        try {
            sessionCtl.update_question(new custom_survey_question__c(session__c = s.id, id = csq.id, question__c = 'question for validate'), new list<custom_survey_option__c>());
        } catch (Exception e){
            system.assertEquals(system.label.specified_question_not_found, e.getMessage());
        	error_found = true;
        }
        system.assertEquals(true, error_found);
        error_found = false;

        csq = create_csq_of_checkbox(s.id);

        // Result will be success.
        sessionCtl.update_question(new custom_survey_question__c(session__c = s.id, id = csq.id, question__c = 'question for validate'), new list<custom_survey_option__c>());
    }

    private static testmethod void validate_update_question_of_choice(){
        session__c s = new session__c(name = 'asdflkjfda');
        insert s;

        custom_survey_question__c csq = new custom_survey_question__c(question__c = 'odjfofdk', session__c = s.id, survey_type__c = 'checkbox');
        list<custom_survey_option__c> csos = new list<custom_survey_option__c>();
        csos.add(new custom_survey_option__c(
            session__c = s.id,
            option__c = 'slkdjflwfjasdf'
        ));
        csos.add(new custom_survey_option__c(
            session__c = s.id,
            option__c = 'fdadffdvdljlkj'
        ));
        sessionCtl.create_question(csq, csos);

        // validate updating question__c
        csq.question__c = 'sajflksjasafd';
        sessionCtl.update_question(csq, csos);
        system.assertEquals('sajflksjasafd', [select question__c from custom_survey_question__c where id = :csq.id].question__c);
        
        // validate adding custom_survey_option
        csos.add(new custom_survey_option__c(
            session__c = s.id,
            option__c = 'sddvdsfdagnjk'
        ));
        sessionCtl.update_question(csq, csos);
        system.assertEquals(3, [select id from custom_survey_option__c where custom_survey_question__c = :csq.id].size());
        
        // validate updating custom_survey_option
        csos[0].option__c = 'vniasdflasdfas';
        sessionCtl.update_question(csq, csos);
        system.assertEquals('vniasdflasdfas', [select option__c from custom_survey_option__c where id = :csos[0].id].option__c);
        
        // validate deleting custom_survey_option__c by not passing custom_survey_options
        csos.remove(0);
        sessionCtl.update_question(csq, csos);
        system.assertEquals(2, [select id from custom_survey_option__c where custom_survey_question__c = :csq.id].size());
        
        // validate deleting custom_survey_option__c by passing blank value
        csos[1].option__c = '';
        sessionCtl.update_question(csq, csos);
        system.assertEquals(1, [select id from custom_survey_option__c where custom_survey_question__c = :csq.id].size());
    }

    private static testmethod void validate_update_question_of_free(){
        session__c s;
        custom_survey_question__c csq;

        s = new session__c(name = 'aiuwoeofnod');
        insert s;
        csq = create_csq_of_free(s.id);

        csq.question__c = 'uiouoewrfoi';

        sessionCtl.update_question(csq, new list<custom_survey_option__c>());

        system.assertEquals('uiouoewrfoi', [select question__c from custom_survey_question__c where session__c = :s.id AND survey_type__c = 'free'].question__c);
    }

    private static testmethod void validate_update_question_of_rating(){
    	session__c s = new session__c(name = 'zcvnejdnforf');
    	insert s;
    	custom_survey_question__c csq = new custom_survey_question__c(session__c = s.id, question__c = 'cvvjdfdfsfg', survey_type__c = 'rating', rating_steps__c = 5);
    	id csq_id = sessionCtl.create_question(csq, null);

    	system.assertEquals(5, [select id from custom_survey_option__c where session__c = :s.id and custom_survey_question__c = :csq_id].size());

    	// invalid rating_steps__c
    	csq = [select id, question__c, session__c, rating_steps__c from custom_survey_question__c where id = :csq_id][0];
    	csq.rating_steps__c = 0;
    	try {
    		sessionCtl.update_question(csq, null);
    	} catch (Exception e){
    		system.assertEquals(system.label.rating_steps_is_invalid, e.getMessage());
    	}
    	csq.rating_steps__c = 11;
    	try {
    		sessionCtl.update_question(csq, null);
    	} catch (Exception e){
    		system.assertEquals(system.label.rating_steps_is_invalid, e.getMessage());
    	}

    	// increase rating_steps__c
    	csq.rating_steps__c = 7;
    	sessionCtl.update_question(csq, null);
    	system.assertEquals(7, [select id from custom_survey_option__c where session__c = :s.id and custom_survey_question__c = :csq.id].size());

    	// decrease rating_steps__c
    	csq.rating_steps__c = 3;
    	sessionCtl.update_question(csq, null);
    	system.assertEquals(3, [select id from custom_survey_option__c where session__c = :s.id and custom_survey_question__c = :csq.id].size());
    }

    private static testmethod void validate_update_question_of_number(){
        session__c s;
        custom_survey_question__c csq;

        s = new session__c(name = 'aiuwoeofnod');
        insert s;
        csq = create_csq_of_number(s.id);

        csq.question__c = 'uiouoewrfoi';
        sessionCtl.update_question(csq, null);
        system.assertEquals('uiouoewrfoi', [select question__c from custom_survey_question__c where session__c = :s.id AND survey_type__c = 'number'].question__c);
    }

    private static testmethod void validate_update_question_of_guest(){
        session__c s = new session__c(name = 'njoewkfmodf', who_can_submit_survey__c = 'Anyone');
        insert s;

    	custom_survey_question__c csq = create_csq_of_guest(s.id);

    	// add field
        list<custom_survey_option__c> csos_to_add = new list<custom_survey_option__c>();
        for (custom_survey_option__c cso : csq.custom_survey_option__r){
            csos_to_add.add(cso);
        }
    	csos_to_add.add(new custom_survey_option__c(
    		option__c = 'sugoisurvey5__Title__c'
		));
		sessionCtl.update_question(csq, csos_to_add);
		system.assertEquals(5, [select id from custom_survey_option__c where session__c = :s.id and custom_survey_question__c = :csq.id].size());

		// del fields
		list<custom_survey_option__c> csos_to_del = new list<custom_survey_option__c>();
    	csos_to_del.add(new custom_survey_option__c(
    		option__c = 'sugoisurvey5__Email__c'
		));
		sessionCtl.update_question(csq, csos_to_del);
		system.assertEquals(1, [select id from custom_survey_option__c where session__c = :s.id and custom_survey_question__c = :csq.id].size());
    }
    
    static testmethod void validate_clear_delivered_flag(){
        session__c session = new session__c(name = 'iuehdfiwhejr');
        insert session;
        
        guest__c guest = new guest__c(
            session__c = session.id, 
            last_name__c = 'lkelkhrlw',
            mail_delivered__c = true, 
            guest_pass_delivered__c = true, 
            survey_link_delivered__c = true,
            handout_delivered__c = true
        );  
        insert guest;
        
        // Negative Case
        // Session Id is null
        try {
            sessionCtl.clear_delivered_flag(null, null);
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
        }
        
        // Negative Case
        // Invalid template string
        try {
            sessionCtl.clear_delivered_flag(session.id, 'kljsldfj');
        } catch (Exception e){
            system.assertEquals(system.label.invalid_value + ' : kljsldfj for template', e.getMessage());
        }
        
        // Positive Case
        // Clear Flag for Mail 
        sessionCtl.clear_delivered_flag(session.id, 'free');
        guest = [select mail_delivered__c, guest_pass_delivered__c, survey_link_delivered__c, handout_delivered__c from guest__c where session__c = :session.id][0];
        system.assertEquals(false, guest.mail_delivered__c);
        system.assertEquals(true, guest.guest_pass_delivered__c);
        system.assertEquals(true, guest.survey_link_delivered__c);
        system.assertEquals(true, guest.handout_delivered__c);
        
        guest.mail_delivered__c = true;
        update guest;
        
        // Positive Case
        // Clear Flag for Guest Pass
        sessionCtl.clear_delivered_flag(session.id, 'guest_pass');
        guest = [select mail_delivered__c, guest_pass_delivered__c, survey_link_delivered__c, handout_delivered__c from guest__c where session__c = :session.id][0];
        system.assertEquals(true, guest.mail_delivered__c);
        system.assertEquals(false, guest.guest_pass_delivered__c);
        system.assertEquals(true, guest.survey_link_delivered__c);
        system.assertEquals(true, guest.handout_delivered__c);
        
        guest.guest_pass_delivered__c = true;
        update guest;
        
        // Positive Case
        // Clear Flag for Survey Link
        sessionCtl.clear_delivered_flag(session.id, 'survey_link');
        guest = [select mail_delivered__c, guest_pass_delivered__c, survey_link_delivered__c, handout_delivered__c from guest__c where session__c = :session.id][0];
        system.assertEquals(true, guest.mail_delivered__c);
        system.assertEquals(true, guest.guest_pass_delivered__c);
        system.assertEquals(false, guest.survey_link_delivered__c);
        system.assertEquals(true, guest.handout_delivered__c);
        
        guest.survey_link_delivered__c = true;
        update guest;
        
        // Positive Case
        // Clear Flag for Handout
        sessionCtl.clear_delivered_flag(session.id, 'handout');
        guest = [select mail_delivered__c, guest_pass_delivered__c, survey_link_delivered__c, handout_delivered__c from guest__c where session__c = :session.id][0];
        system.assertEquals(true, guest.mail_delivered__c);
        system.assertEquals(true, guest.guest_pass_delivered__c);
        system.assertEquals(true, guest.survey_link_delivered__c);
        system.assertEquals(false, guest.handout_delivered__c);
    }
    
    static testmethod void validate_get_guests_to_be_delivered(){
        list<guest__c> guests;
        
        session__c session = new session__c(name = '7rfhihidhf');
        insert session;
        
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'a@hoge.com', status__c = 'submitted');
 
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'd@hoge.com', status__c = 'registered', mail_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'e@hoge.com', status__c = 'attended', mail_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'f@hoge.com', status__c = 'submitted', mail_delivered__c = true);
        
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'g@hoge.com', status__c = 'registered', guest_pass_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'h@hoge.com', status__c = 'attended', guest_pass_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'i@hoge.com', status__c = 'submitted', guest_pass_delivered__c = true);
        
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'j@hoge.com', status__c = 'registered', survey_link_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'k@hoge.com', status__c = 'attended', survey_link_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'l@hoge.com', status__c = 'submitted', survey_link_delivered__c = true);
        
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'm@hoge.com', status__c = 'registered', handout_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'n@hoge.com', status__c = 'attended', handout_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'o@hoge.com', status__c = 'submitted', handout_delivered__c = true);
        
        insert new guest__c(session__c = session.id, last_name__c = 'a', status__c = 'submitted');
        
        
        // Negative Case
        // Required Field is missing
        try {
            sessionCtl.get_guests_to_be_delivered(null, null, null);
        } catch (Exception e){
            system.assertEquals(system.label.required_parameter_is_missing, e.getMessage());
        }
        
        // Positive Case
        for (string template : new list<string>{'free', 'guest_pass', 'survey_link', 'handout'}){
            guests = sessionCtl.get_guests_to_be_delivered(session.id, template, 'Anyone');
            system.assertEquals(10, guests.size());
            
            guests = sessionCtl.get_guests_to_be_delivered(session.id, template, 'attendees');
            system.assertEquals(7, guests.size());
            
            guests = sessionCtl.get_guests_to_be_delivered(session.id, template, 'who_have_submitted_survey');
            system.assertEquals(4, guests.size());
        }
    }
    
    /*
    static testmethod void validate_send_mail(){
        try {
            sessionCtl.send_mail(null, 'free', 'anyone', 'test sub', 'test body', 'test@hoge.com', null);
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
        }
        
        
        session__c session = new session__c(name = 'ihqwefadfasdf');
        insert session;
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'a@hoge.com', status__c = 'submitted');
        
        // Negative Case
        // Empty value for template
        try {
            sessionCtl.send_mail(session.id, null, 'anyone', 'test sub', 'test body', 'test@hoge.com', null);
        } catch (Exception e){
            system.assertEquals(system.label.required_parameter_is_missing + ' : template', e.getMessage());
        }
        
        
        // Negative Case
        // Invalid value for template
        try {
            sessionCtl.send_mail(session.id, 'hoge', 'anyone', 'test sub', 'test body', 'test@hoge.com', null);
        } catch (Exception e){
            system.assertEquals(system.label.invalid_value + ' : hoge for template', e.getMessage());
        }

        // Negative Case
        // Empty value for to
        try {
            sessionCtl.send_mail(session.id, 'free', null, 'test sub', 'test body', 'test@hoge.com', null);
        } catch (Exception e){
            system.assertEquals(system.label.required_parameter_is_missing + ' : to', e.getMessage());
        }
        
        
        // Negative Case
        // Invalid value for to
        try {
            sessionCtl.send_mail(session.id, 'free', 'hoge', 'test sub', 'test body', 'test@hoge.com', null);
        } catch (Exception e){
            system.assertEquals(system.label.invalid_value + ' : hoge for to', e.getMessage());
        }
        
        
        // Positive Case
        for (string template : new list<string>{'free', 'guest_pass', 'survey_link', 'handout'}) {
            integer r = sessionCtl.send_mail(session.id, template, 'anyone', 'test sub', 'test body', 'test@hoge.com', null);
            system.assertEquals(1, r);
            
            // check dedupe
            r = sessionCtl.send_mail(session.id, template, 'anyone', 'test sub', 'test body', 'test@hoge.com', null);
            system.assertEquals(0, r);
        }
    }
    */

    private static custom_survey_question__c create_csq_of_checkbox(id session_id){
         return create_csq_of_checkbox(session_id, false, true);
    }

    private static custom_survey_question__c create_csq_of_checkbox(id session_id, boolean required, boolean enable_free_form){
        custom_survey_question__c csq = new custom_survey_question__c(session__c = session_id, question__c = 'checkbox_aslfasdkf', survey_type__c = 'checkbox', required__c = required, enable_free_form__c = enable_free_form);

        list<custom_survey_option__c> csos = new list<custom_survey_option__c>();
        csos.add(new custom_survey_option__c(session__c = session_id, option__c = 'ansldfasfj'));
        csos.add(new custom_survey_option__c(session__c = session_id, option__c = 'basdffdsaf'));
        
        sessionCtl.create_question(csq, csos);

        string soql_flds_csq = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Question__c');
        string soql_flds_cso = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Option__c');
        string csq_id = csq.id;
        string soql = 'select ' + soql_flds_csq + ', (select ' + soql_flds_cso + ' from custom_survey_option__r) from custom_survey_question__c where id = :csq_id';
        list<custom_survey_question__c> csqs = Database.query(soql);
        return csqs[0];
    }

    private static custom_survey_question__c create_csq_of_free(id session_id){
        return create_csq_of_free(session_id, false);
    }

    private static custom_survey_question__c create_csq_of_free(id session_id, boolean required){
        custom_survey_question__c csq = new custom_survey_question__c(session__c = session_id, question__c = 'free_lkajsdfadsf', survey_type__c = 'free', required__c = required);
        sessionCtl.create_question(csq, null);

        string soql_flds_csq = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Question__c');
        string soql_flds_cso = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Option__c');
        string csq_id = csq.id;
        string soql = 'select ' + soql_flds_csq + ', (select ' + soql_flds_cso + ' from custom_survey_option__r) from custom_survey_question__c where id = :csq_id';
        list<custom_survey_question__c> csqs = Database.query(soql);
        return csqs[0];
    }

    private static custom_survey_question__c create_csq_of_rating(id session_id){
        return create_csq_of_rating(session_id, false);
    }

    private static custom_survey_question__c create_csq_of_rating(id session_id, boolean required){
        custom_survey_question__c csq = new custom_survey_question__c(session__c = session_id, question__c = 'rating_lasdfasdf', survey_type__c = 'rating', required__c = required, rating_steps__c = 5);
        sessionCtl.create_question(csq, null);

        string soql_flds_csq = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Question__c');
        string soql_flds_cso = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Option__c');
        string csq_id = csq.id;
        string soql = 'select ' + soql_flds_csq + ', (select ' + soql_flds_cso + ' from custom_survey_option__r) from custom_survey_question__c where id = :csq_id';
        list<custom_survey_question__c> csqs = Database.query(soql);
        return csqs[0];
    }

    private static custom_survey_question__c create_csq_of_number(id session_id){
        return create_csq_of_number(session_id, false);
    }

    private static custom_survey_question__c create_csq_of_number(id session_id, boolean required){
        custom_survey_question__c csq = new custom_survey_question__c(session__c = session_id, question__c = 'number_aslfasdkf', survey_type__c = 'number', required__c = required);
        sessionCtl.create_question(csq, null);

        string soql_flds_csq = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Question__c');
        string soql_flds_cso = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Option__c');
        string csq_id = csq.id;
        string soql = 'select ' + soql_flds_csq + ', (select ' + soql_flds_cso + ' from custom_survey_option__r) from custom_survey_question__c where id = :csq_id';
        list<custom_survey_question__c> csqs = Database.query(soql);
        return csqs[0];
    }

    private static custom_survey_question__c create_csq_of_guest(id session_id){
        return create_csq_of_guest(session_id, false);
    }

    private static custom_survey_question__c create_csq_of_guest(id session_id, boolean required){
        custom_survey_question__c csq = new custom_survey_question__c(session__c = session_id, question__c = 'guest_aslfasdkf', survey_type__c = 'guest', required__c = required);

        list<custom_survey_option__c> csos = new list<custom_survey_option__c>();
        csos.add(new custom_survey_option__c(session__c = session_id, option__c = 'sugoisurvey5__Last_Name__c'));
        csos.add(new custom_survey_option__c(session__c = session_id, option__c = 'sugoisurvey5__First_Name__c'));
        csos.add(new custom_survey_option__c(session__c = session_id, option__c = 'sugoisurvey5__Company__c'));
        csos.add(new custom_survey_option__c(session__c = session_id, option__c = 'sugoisurvey5__Email__c', required__c = required));

        sessionCtl.create_question(csq, csos);

        string soql_flds_csq = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Question__c');
        string soql_flds_cso = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Option__c');
        string csq_id = csq.id;
        string soql = 'select ' + soql_flds_csq + ', (select ' + soql_flds_cso + ' from custom_survey_option__r) from custom_survey_question__c where id = :csq_id';
        list<custom_survey_question__c> csqs = Database.query(soql);
        return csqs[0];
    }
}