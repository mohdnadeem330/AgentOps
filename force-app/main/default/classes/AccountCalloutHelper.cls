public class AccountCalloutHelper {
    
    public static Boolean ACCOUNT_CALLOUT_FINISHED = FALSE; //INTEG_ISSUE_FIX_SS

    public static void PrepareDataForCallout(List<Id> accIds){
        List<Account> accList = AccountService.queryAllFieldsWithExtraFields(accIds);
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> sbdList = new List<Object>();

        for (Account acc: accList) {
            Map<String, Object> sbdMap = new Map<String, Object>();
            
            String recordMode = String.isBlank(acc.ERPID__c) ? Constants.MULESOFT_CREATE_MODE : Constants.MULESOFT_UPDATE_MODE;
            
            sbdMap.put('recordMode', recordMode);
            sbdMap.put('createdByUser', String.isBlank(acc.ERPID__c) ? acc.CreatedBy.Email : acc.Owner.Email);
            // sbdMap.put('createdByUser', 'VPAWAR@aldar.com');
            sbdMap.put('vendorName', acc.Name);
            sbdMap.put('vendorNameAlt', acc.Name);
            sbdMap.put('taxReference', acc.UAEVATRegisterNumber__c);
            sbdMap.put('currencyCode', acc.CurrencyIsoCode);
            sbdMap.put('vatRegistrationNumber', acc.UAEVATRegisterNumber__c);
            sbdMap.put('startDateActive', acc.DateOfRegistration__c);
            sbdMap.put('supTradeLicNumber', acc.RegistrationNumber__c);
            sbdMap.put('vendorSiteCode', 'ALDAR');  // fixed
            sbdMap.put('addressLine1', acc.BillingStreet);
            sbdMap.put('city', acc.BillingCity);
            sbdMap.put('state', acc.BillingState);
            sbdMap.put('country', acc.BillingCountryCode);
            sbdMap.put('postalCodeZip', acc.BillingPostalCode);
            sbdMap.put('orgId', '711'); // fixed
            sbdMap.put('emailAddress', acc.Email__c);
            sbdMap.put('url', acc.Website);
            sbdMap.put('supAmlFlag', acc.AMLFlag__c ? 'Y' : 'N');
            sbdMap.put('supTradeLicenddate', acc.RegistrationExpiryDate__c);
            sbdMap.put('brokManagement', '');
            sbdMap.put('location', acc.BillingCountry);
            sbdMap.put('resCategory', '');
            sbdMap.put('prevCategory', acc.PreviousAgencyStatus__c == '' ? 'Pending Verification' : acc.PreviousAgencyStatus__c == 'In Active' ? 'Non Active' : acc.PreviousAgencyStatus__c);
            //sbdMap.put('currCategory', acc.AgencyStatus__c == 'In Active' ? 'Non Active' : acc.AgencyStatus__c);
            sbdMap.put('currCategory', acc.CurrentAgencyStatus__c == '' ? 'Pending Verification' : acc.CurrentAgencyStatus__c);
            sbdMap.put('region', acc.AgencyRegion__c == 'Domestic' ? 'UAE' : acc.AgencyRegion__c.toUpperCase());
            sbdMap.put('brokPhoneNumber', '');
            sbdMap.put('dateOfReg', acc.DateOfRegistration__c);
            sbdMap.put('refSalesManager', '');
            sbdMap.put('isBrokerChanged', acc.IsBrokerChange__c ? 'Y' : 'N');
            sbdMap.put('isAgentChanged', acc.IsAgentChange__c ? 'Y' : 'N');
            sbdMap.put('SfSupplierId', acc.Id);
            sbdMap.put('SfResourceId', '');
            sbdMap.put('SfSiteId', '');
            sbdMap.put('OracleResourceId', acc.ERPID__c);
            //sbdMap.put('eidPlaceofIssuance', acc.EIDPlaceofissuance__c != null ? acc.EIDPlaceofissuance__c : '');

            // Added By Moh Sarfaraj for BPE-164 starts
            System.debug('test Acc ids--'+AccountTriggerHandler.setAccountIdsToSendBankDetailsToERP);
            if(Trigger.isInsert || AccountTriggerHandler.setAccountIdsToSendBankDetailsToERP.contains(acc.Id)){
                if(String.isNotBlank(recordMode)){
                    // Set new Bank Details for ERP
                    sbdMap.put('bankName', String.isNotBlank(acc.BankName__c) ? acc.BankName__c : '');
                    sbdMap.put('bankAccountNumber', String.isNotBlank(acc.BankAccountNumber__c) ? acc.BankAccountNumber__c : '');
                    sbdMap.put('swiftCode', String.isNotBlank(acc.SwiftCode__c) ? acc.SwiftCode__c : '');
                    sbdMap.put('ibanNumber', String.isNotBlank(acc.IBANNumber__c) ? acc.IBANNumber__c : ''); 
                    sbdMap.put('bankCountry', String.isNotBlank(acc.BankCountry__c) ? acc.BankCountry__c : '');
                    sbdMap.put('bankCurrency', String.isNotBlank(acc.CurrencyIsoCode) ? acc.CurrencyIsoCode : '');
                    sbdMap.put('branchAddress', String.isNotBlank(acc.BranchAddress__c) ? acc.BranchAddress__c : '');

                    // Added By Moh Sarfaraj for BPM-428 
                    if(acc.AgencyRegion__c.equalsIgnoreCase('International')){
                        sbdMap.put('beneficiaryName', String.isNotBlank(acc.BeneficiaryName__c) ? acc.BeneficiaryName__c : '');
                    }                
                }

                if(String.isNotBlank(recordMode) && recordMode == Constants.MULESOFT_UPDATE_MODE){
                    // Set Old Bank Details for ERP
                    sbdMap.put('oldBankName', String.isNotBlank(acc.OldBankName__c) ? acc.OldBankName__c : '');
                    sbdMap.put('oldBankAccountNumber', String.isNotBlank(acc.OldBankAccountNumber__c) ? acc.OldBankAccountNumber__c : '');
                    sbdMap.put('oldSwiftCode', String.isNotBlank(acc.OldSwiftCode__c) ? acc.OldSwiftCode__c : '');
                    sbdMap.put('oldIbanNumber', String.isNotBlank(acc.OldIBANNumber__c) ? acc.OldIBANNumber__c : '');
                    sbdMap.put('oldBankCountry', String.isNotBlank(acc.OldBankCountry__c) ? acc.OldBankCountry__c : '');
                    sbdMap.put('oldBankCurrency', String.isNotBlank(acc.CurrencyIsoCode) ? acc.CurrencyIsoCode : '');
                    sbdMap.put('oldBranchAddress', String.isNotBlank(acc.OldBranchAddress__c) ? acc.OldBranchAddress__c : '');

                    // Added By Moh Sarfaraj for BPM-428 
                    if(acc.AgencyRegion__c.equalsIgnoreCase('International')){
                        sbdMap.put('OldBeneficiaryName', String.isNotBlank(acc.OldBeneficiaryName__c) ? acc.OldBeneficiaryName__c : '');
                    }                
                }
            }
            // Added By Moh Sarfaraj for BPE-164 end

            Map<String, Object> oIds = new Map<String, Object>();
            if (acc.OtherERPID__c != null) {
                oIds = (Map<String, Object>)JSON.deserializeUntyped(acc.OtherERPID__c);
                for (String key: oIds.keySet()) {
                    oIds.put(key.toLowerCase(), oIds.get(key));
                }
            }
            sbdMap.put('OracleSupplierId', !oIds.isEmpty() && oIds.containsKey('oraclesupplierid') ? String.valueOf(oIds.get('oraclesupplierid')) : '');
            sbdMap.put('OracleSiteId', !oIds.isEmpty() && oIds.containsKey('oraclesiteid') ? String.valueOf(oIds.get('oraclesiteid')) : '');
            
            List<Object> adList = new List<Object>();
            
            Boolean isNoAgentContact = true;
            Boolean isNoAGENCY_ADMINContactFound = true;
            for (Contact con: acc.Contacts) {
                if (con.BrokerType__c == Constants.AGENCY_ADMIN) {
                    
                    sbdMap.put('contactPhoneCountryCode', con.MobileCountryCode__c);
                    sbdMap.put('contactPhoneAreaCode', '');
                    sbdMap.put('contactPhoneNumber', con.MobilePhone__c != null ? con.MobilePhone__c : con.Phone);  // Mapping is unclear
                    sbdMap.put('contactFname', con.FirstName);
                    sbdMap.put('contactMname', con.MiddleName);
                    sbdMap.put('contactLname', con.LastName);
                    // Tharun changed below Title to Salutation
                    sbdMap.put('contactTitle', con.Salutation != null ? con.Salutation.replace('.','') : '');
                    sbdMap.put('contactEmail', con.Email);
                    sbdMap.put('SfContactId', con.Id);
                    String contactERPId = '';
                    if (!oIds.isEmpty() && oIds.containsKey('sfcontactid') && oIds.get('sfcontactid') == con.Id && oIds.containsKey('oraclecontactid')) {
                        contactERPId = String.valueOf(oIds.get('oraclecontactid'));
                    }
                    sbdMap.put('OracleContactId', contactERPId);
                    isNoAGENCY_ADMINContactFound = false;
                }
                if (con.BrokerType__c != null) {
                    isNoAgentContact = false;
                    
                    Map<String, Object> adMap = new Map<String, Object>();
                    
                    adMap.put('SfSupplierId', acc.Id);
                    adMap.put('SfResourceId', '');
                    adMap.put('agentId', con.Id);
                    adMap.put('oracleAgentId', con.ERPID__c);
                    adMap.put('agentName', con.Name);
                    adMap.put('activeFlag', con.AgentStatus__c == Constants.ACTIVE_AGENT_STATUS ? 'Y' : 'N');
                    adMap.put('startDate', '');
                    adMap.put('endDate', '');
                    
                    adList.add(adMap);
                }
            }
            System.debug('isNoAGENCY_ADMINContactFound -> '+isNoAGENCY_ADMINContactFound);
            if (isNoAGENCY_ADMINContactFound) { //SS_FIX_FOR_NO_AGENCY_ADMIN_ISSUE
                sbdMap.put('contactPhoneCountryCode', '');
                sbdMap.put('contactPhoneAreaCode', '');
                sbdMap.put('contactPhoneNumber', '');
                sbdMap.put('contactFname', '');
                sbdMap.put('contactMname', '');
                sbdMap.put('contactLname', '');
                sbdMap.put('contactTitle', '');
                sbdMap.put('contactEmail', '');
                sbdMap.put('SfContactId', '');
                sbdMap.put('OracleContactId', '');
            }
            if (isNoAgentContact) {
                Map<String, Object> adMap = new Map<String, Object>();
                    
                adMap.put('SfSupplierId', '');
                adMap.put('SfResourceId', '');
                adMap.put('agentId', '');
                adMap.put('oracleAgentId', '');
                adMap.put('agentName', '');
                adMap.put('activeFlag', '');
                adMap.put('startDate', '');
                adMap.put('endDate', '');
                
                adList.add(adMap);
            }
            sbdMap.put('agentDetails', adList);
            sbdList.add(sbdMap);
        }
        finalMap.put('supplBrokerDetails', sbdList);
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replaceAll(':null', ':""');
        System.debug('requestBody>>>' + requestBody);
         if (!sbdList.isEmpty() && System.isFuture() == false) { 
            if (System.IsBatch() == true && !Trigger.isExecuting && !ACCOUNT_CALLOUT_FINISHED) {
                CalloutToMuleSoft.calloutService(requestBody, true, Constants.AGENCY_INTEGRATION, accIds);  
            } else if(!System.IsBatch() && Trigger.isExecuting && !ACCOUNT_CALLOUT_FINISHED){
                CalloutToMuleSoft.calloutFutureService(requestBody, true, Constants.AGENCY_INTEGRATION, accIds);    
            }
            ACCOUNT_CALLOUT_FINISHED = TRUE;
        }
        
        
        /* INTEGRATION ISSUE FIXES ARE BELOW - COMMENTED BY SARAN TO PROCEED PROD MIGRATION - STILL UAT TESTING GOING ON
        //To Stop Calling the API  Multiple Times in a same transactions - 
        //ACCOUNT_CALLOUT_FINISHED Flag will be set to True Once API Invoked
        if (!ACCOUNT_CALLOUT_FINISHED && !sbdList.isEmpty() && System.isFuture() == false) { //INTEG_ISSUE_FIX_SS
            //if (System.IsBatch() == true) { //INTEG_ISSUE_FIX_SS
            if (System.IsBatch() == true && !CalloutToMuleSoft.isFromTrigger) { //INTEG_ISSUE_FIX_SS
                ACCOUNT_CALLOUT_FINISHED = TRUE;
                CalloutToMuleSoft.calloutService(requestBody, true, Constants.AGENCY_INTEGRATION, accIds);
            } else if(System.IsBatch() == FALSE) { //INTEG_ISSUE_FIX_SS
                //Future and Batch Shouldn't invoke Future
                //Trigger can invoke Future callout method
                ACCOUNT_CALLOUT_FINISHED = TRUE;
                CalloutToMuleSoft.calloutFutureService(requestBody, true, Constants.AGENCY_INTEGRATION, accIds);
            }
        }
        */
    }
}