@isTest
public class CustomerUpdatePaymentWebServiceTest {

    @isTest
    public static void testCustomerUpdatePaymentWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receipt;

        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receipt.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        insert receiptAllocation;
        
        TestObjectsFactory.initializeRestContext(null, '/query/updatepayment');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String reqBody = '{"receiptId": "' + receipt.Id + '","responseBody": {"transaction_id":"6630695484066957004048","signed_field_names":"transaction_id","signed_date_time":"2022-09-13T11:45:49Z","signature":"y5j4hCOsMG3K54JDERCROHABaXd7aYnZekTf9hjlN9g=","authorizedAmount":"100","score_velocity_info":"VEL-CC^VEL-NAME^VELI-TIP^VELL-TIP^VELS-FP^VELS-TIP","score_time_local":"15:45:48","score_suspicious_info":"ANOM-SRES^DEV-MOB^MUL-EM^RISK-DEV","score_score_result":"69","score_rmsg":"Score exceeds threshold. Score = 69","score_rflag":"DSCORE","score_return_code":"1072000","score_reason_code":"100","score_rcode":"1","score_model_used":"default_cemea","score_ip_state":"du","score_ip_routing_method":"mobile gateway","score_ip_country":"ae","score_ip_city":"dubayy","score_internet_info":"FREE-EM^MM-IPBCO","score_identity_info":"MORPH-C","score_host_severity":"1","score_factors":"B^H","score_device_fingerprint_true_ipaddress_country":"AE","score_device_fingerprint_true_ipaddress_city":"dubayy","score_device_fingerprint_true_ipaddress_attributes":"_CHALLENGED^_CHALLENGE_PASSED^_TRUSTED_CONF","score_device_fingerprint_true_ipaddress":"5.30.9.73","score_device_fingerprint_smart_id_confidence_level":"100.00","score_device_fingerprint_smart_id":"16a63f8ccce64f83958546aa7a6dd956","score_device_fingerprint_screen_resolution":"2210x1770","score_device_fingerprint_javascript_enabled":"true","score_device_fingerprint_images_enabled":"false","score_device_fingerprint_hash":"16a63f8ccce64f83958546aa7a6dd956","score_device_fingerprint_flash_enabled":"false","score_device_fingerprint_cookies_enabled":"true","score_device_fingerprint_browser_language":"en-US,en;q=0.9,ru;q=0.8","score_card_scheme":"VISA DEBIT","score_card_issuer":"EMIRATES ISLAMIC BANK P.J.S.C.","score_card_account_type":"Visa Platinum","score_bin_country":"AE","score_address_info":"MM-BIN^UNV-ADDR","request_token":"Axj//wSTZ3Nii9Qdwo0Q/7Us2bM2DZy1aOGjBs2ctW7Bg0YNHCecI3o9mAKecI3o9mYgX1Z+ARoQyaSZejFhV2cGDSTZ3Nii9Qdwo0QA1SxK","req_transaction_uuid":"' + receipt.Id + '-1663069435542","req_transaction_type":"sale","req_reference_number":"' + receipt.Id + '-1663069435542","req_profile_id":"51A62E3B-BF68-49FF-AF3D-95C21F5EBB3D","req_payment_method":"card","req_payer_authentication_merchant_name":"ADCB","req_payer_authentication_indicator":"01","req_payer_authentication_acs_window_size":"03","req_locale":"en","req_device_fingerprint_id":"7b19d89121814127b5ad6ea20fcb632d","req_currency":"AED","req_card_type_selection_indicator":"1","req_card_type":"001","req_card_number":"xxxxxxxxxxxx4027","req_card_expiry_date":"05-2027","req_bill_to_surname":"Akhmedova","req_bill_to_phone":"79028680407","req_bill_to_forename":"Zhamilia","req_bill_to_email":"bulat.ford@gmail.com","req_bill_to_address_state":"MOW","req_bill_to_address_line1":"St Lipoviy Park, building 7, Apartment 376","req_bill_to_address_country":"RU","req_bill_to_address_city":"Moscow","req_amount":"70000.00","req_access_key":"4cd8fabc32aa3afdb0d817afdd95c2c4","reason_code":"100","payment_account_reference":"V0010015821303504218452153753","payer_authentication_xid":"AAUCBkgiOQAAas/AeEJWdQAAAAA=","payer_authentication_validate_result":"0","payer_authentication_validate_e_commerce_indicator":"vbv","payer_authentication_transaction_id":"S1JDLeDVIXY92rUcsaz1","payer_authentication_specification_version":"2.2.0","payer_authentication_reason_code":"100","payer_authentication_pares_status":"Y","payer_authentication_enroll_veres_enrolled":"Y","payer_authentication_eci":"05","payer_authentication_cavv":"AAUCBkgiOQAAas/AeEJWdQAAAAA=","payer_authentication_acs_transaction_id":"8258e3ea-ac56-4368-a819-d27e5084c9a9","message":"Request was processed successfully.","decision_velocity_info":"GVEL-R34^GVEL-R36","decision_rmsg":"Service processed successfully","decision_rflag":"SOK","decision_return_code":"1320000","decision_reason_code":"100","decision_rcode":"1","decision_early_return_code":"9999999","decision_early_reason_code":"100","decision_early_rcode":"1","decision_case_priority":"3","decision":"ACCEPT","card_type_name":"Visa","bill_trans_ref_no":"6630695484066957004048","auth_trans_ref_no":"6630695484066957004048","auth_time":"2022-09-13T114549Z","auth_response":"00","auth_reconciliation_reference_number":"225611012283","auth_cv_result_raw":"M","auth_cv_result":"M","auth_code":"381980","auth_cavv_result_raw":"2","auth_cavv_result":"2","auth_avs_code_raw":"U","auth_avs_code":"U","auth_amount":"70000.00"}}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerUpdatePaymentWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerUpdatePaymentWebServiceError() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receipt;

        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receipt.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        insert receiptAllocation;
        
        TestObjectsFactory.initializeRestContext(null, '/query/updatepayment');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String reqBody = '{"receiptId": "' + receipt.Id + '123","responseBody": {"transaction_id":"6630695484066957004048","signed_field_names":"transaction_id","signed_date_time":"2022-09-13T11:45:49Z","signature":"y5j4hCOsMG3K54JDERCROHABaXd7aYnZekTf9hjlN9g=","authorizedAmount":"100","score_velocity_info":"VEL-CC^VEL-NAME^VELI-TIP^VELL-TIP^VELS-FP^VELS-TIP","score_time_local":"15:45:48","score_suspicious_info":"ANOM-SRES^DEV-MOB^MUL-EM^RISK-DEV","score_score_result":"69","score_rmsg":"Score exceeds threshold. Score = 69","score_rflag":"DSCORE","score_return_code":"1072000","score_reason_code":"100","score_rcode":"1","score_model_used":"default_cemea","score_ip_state":"du","score_ip_routing_method":"mobile gateway","score_ip_country":"ae","score_ip_city":"dubayy","score_internet_info":"FREE-EM^MM-IPBCO","score_identity_info":"MORPH-C","score_host_severity":"1","score_factors":"B^H","score_device_fingerprint_true_ipaddress_country":"AE","score_device_fingerprint_true_ipaddress_city":"dubayy","score_device_fingerprint_true_ipaddress_attributes":"_CHALLENGED^_CHALLENGE_PASSED^_TRUSTED_CONF","score_device_fingerprint_true_ipaddress":"5.30.9.73","score_device_fingerprint_smart_id_confidence_level":"100.00","score_device_fingerprint_smart_id":"16a63f8ccce64f83958546aa7a6dd956","score_device_fingerprint_screen_resolution":"2210x1770","score_device_fingerprint_javascript_enabled":"true","score_device_fingerprint_images_enabled":"false","score_device_fingerprint_hash":"16a63f8ccce64f83958546aa7a6dd956","score_device_fingerprint_flash_enabled":"false","score_device_fingerprint_cookies_enabled":"true","score_device_fingerprint_browser_language":"en-US,en;q=0.9,ru;q=0.8","score_card_scheme":"VISA DEBIT","score_card_issuer":"EMIRATES ISLAMIC BANK P.J.S.C.","score_card_account_type":"Visa Platinum","score_bin_country":"AE","score_address_info":"MM-BIN^UNV-ADDR","request_token":"Axj//wSTZ3Nii9Qdwo0Q/7Us2bM2DZy1aOGjBs2ctW7Bg0YNHCecI3o9mAKecI3o9mYgX1Z+ARoQyaSZejFhV2cGDSTZ3Nii9Qdwo0QA1SxK","req_transaction_uuid":"' + receipt.Id + '-1663069435542","req_transaction_type":"sale","req_reference_number":"0058d0000046eNgAAI","req_profile_id":"51A62E3B-BF68-49FF-AF3D-95C21F5EBB3D","req_payment_method":"card","req_payer_authentication_merchant_name":"ADCB","req_payer_authentication_indicator":"01","req_payer_authentication_acs_window_size":"03","req_locale":"en","req_device_fingerprint_id":"7b19d89121814127b5ad6ea20fcb632d","req_currency":"AED","req_card_type_selection_indicator":"1","req_card_type":"001","req_card_number":"xxxxxxxxxxxx4027","req_card_expiry_date":"05-2027","req_bill_to_surname":"Akhmedova","req_bill_to_phone":"79028680407","req_bill_to_forename":"Zhamilia","req_bill_to_email":"bulat.ford@gmail.com","req_bill_to_address_state":"MOW","req_bill_to_address_line1":"St Lipoviy Park, building 7, Apartment 376","req_bill_to_address_country":"RU","req_bill_to_address_city":"Moscow","req_amount":"70000.00","req_access_key":"4cd8fabc32aa3afdb0d817afdd95c2c4","reason_code":"100","payment_account_reference":"V0010015821303504218452153753","payer_authentication_xid":"AAUCBkgiOQAAas/AeEJWdQAAAAA=","payer_authentication_validate_result":"0","payer_authentication_validate_e_commerce_indicator":"vbv","payer_authentication_transaction_id":"S1JDLeDVIXY92rUcsaz1","payer_authentication_specification_version":"2.2.0","payer_authentication_reason_code":"100","payer_authentication_pares_status":"Y","payer_authentication_enroll_veres_enrolled":"Y","payer_authentication_eci":"05","payer_authentication_cavv":"AAUCBkgiOQAAas/AeEJWdQAAAAA=","payer_authentication_acs_transaction_id":"8258e3ea-ac56-4368-a819-d27e5084c9a9","message":"Request was processed successfully.","decision_velocity_info":"GVEL-R34^GVEL-R36","decision_rmsg":"Service processed successfully","decision_rflag":"SOK","decision_return_code":"1320000","decision_reason_code":"100","decision_rcode":"1","decision_early_return_code":"9999999","decision_early_reason_code":"100","decision_early_rcode":"1","decision_case_priority":"3","decision":"ACCEPT","card_type_name":"Visa","bill_trans_ref_no":"6630695484066957004048","auth_trans_ref_no":"6630695484066957004048","auth_time":"2022-09-13T114549Z","auth_response":"00","auth_reconciliation_reference_number":"225611012283","auth_cv_result_raw":"M","auth_cv_result":"M","auth_code":"381980","auth_cavv_result_raw":"2","auth_cavv_result":"2","auth_avs_code_raw":"U","auth_avs_code":"U","auth_amount":"70000.00"}}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerUpdatePaymentWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}