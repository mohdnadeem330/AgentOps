public class CustomerCalloutHelper {
    public static void PrepareDataForCallout(List<Id> accIds, List<Id> otherObjectIds, String objectName){
        
        List<Account> accList = AccountService.queryAllFieldsWithExtraFields(accIds);
        
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> cdList = new List<Object>();
		
       
        
        // Change starts here by Nikhil
        List<MobileCountryMapping__c> mobCountry = [Select Id,Country_Code__c, ERP_Country__c, Salesforce_Country__c,Salesforce_Country_Code__c  FROM MobileCountryMapping__c];
        Map<String,MobileCountryMapping__c> mobCountrtMap = new Map<String,MobileCountryMapping__c>();
        for(MobileCountryMapping__c mobCountObj : mobCountry){
            mobCountrtMap.put(mobCountObj.Salesforce_Country_Code__c,mobCountObj);
        }
        List<ERPCountryMapping__c> countryList = [Select Id,Salesforce_Country__c, ERP_Country__c From ERPCountryMapping__c];
        Map<String,ERPCountryMapping__c> countryMap = new Map<String,ERPCountryMapping__c>();
        for(ERPCountryMapping__c erpCount : countryList){
            countryMap.put(erpCount.Salesforce_Country__c,erpCount);
        }
        //Change ends here by Nikhil
		
        for (Account acc: accList) {
            Map<String, Object> cdMap = new Map<String, Object>();
            
            String recordMode = String.isBlank(acc.ERPID__c) ? Constants.MULESOFT_CREATE_MODE : Constants.MULESOFT_UPDATE_MODE;
            String mobileCountryCode = '';
            if (acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT) {
                mobileCountryCode = acc.MobileCountryCode__pc != null && acc.MobileCountryCode__pc.contains('+') ? acc.MobileCountryCode__pc.substring(1, acc.MobileCountryCode__pc.length()) : acc.MobileCountryCode__pc;
            } else {
                mobileCountryCode = acc.MobileCountryCode__c != null && acc.MobileCountryCode__c.contains('+') ? acc.MobileCountryCode__c.substring(1, acc.MobileCountryCode__c.length()) : acc.MobileCountryCode__c;
            }
			 System.debug('mobileCountryCode before>>'+mobileCountryCode);
			// Change starts here by Nikhil
            if(mobCountrtMap.containsKey(mobileCountryCode) && 
               mobCountrtMap.get(mobileCountryCode).Country_Code__c != mobileCountryCode){
                mobileCountryCode = mobCountrtMap.get(mobileCountryCode).Country_Code__c;
            }
            System.debug('mobileCountryCode>>'+mobileCountryCode);
            String billingCountry = String.isNotBlank(acc.BillingCountry) ? acc.BillingCountry : '';
            if(billingCountry != '' && countryMap.containsKey(billingCountry)){
                billingCountry = countryMap.get(billingCountry).ERP_Country__c;
            }
			//Change ends here by Nikhil
			
            cdMap.put('sfId', acc.Id);
            cdMap.put('custType', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? 'ORGANIZATION' : 'PERSON');
            cdMap.put('organizationName', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.Name : '');
            cdMap.put('registrationNumber', acc.RegistrationNumber__c);
            cdMap.put('issueDate', acc.RegistrationIssueDate__c);
            cdMap.put('expiryDate', acc.RegistrationExpiryDate__c);
            cdMap.put('placeOfRegistration', acc.PlaceOfRegistration__c);
            cdMap.put('nameInArabic', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.NameInArabic__c : ''); // for Organization
            cdMap.put('nameArabic', acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT ? acc.NameInArabic__c : '');   // for Person
            cdMap.put('motherNameArabic', acc.MotherNameArabic__pc);
            cdMap.put('tradeName', acc.TradeName__c);
            cdMap.put('unifiedNumber', acc.UnifiedNumber__c);
            cdMap.put('typeOfCompany', acc.TypeOfCompany__c);
            cdMap.put('owner', '');   // need to check by Venu
            cdMap.put('fullyOwnedByUaeNational', '');   // need to check by Venu
            cdMap.put('tenantIndustry', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.Industry : '');   // List Of Values | by Venu
            cdMap.put('customerClass', '');   // List Of Values | by Venu
            cdMap.put('investmentValue', '');   // List Of Values | by Venu
            cdMap.put('currentValueRating', acc.CurrentValueRating__c);
            cdMap.put('potentialValueRatingOrg', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.PotentialValueRating__c : ''); // for Organization
            cdMap.put('potentialValueRating', acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT ? acc.PotentialValueRating__c : '');   // for Person
            cdMap.put('influenceRating', '');   // List Of Values | by Venu
            cdMap.put('loyaltyOrg', acc.Loyalty__c);
            cdMap.put('placeOfIncorporation', '');   // need to check by Venu
            cdMap.put('gateReminderLetter', '');   // Date value
            cdMap.put('gateExpiryLetter', '');   // Date Value
            cdMap.put('preNameAdjunct', acc.Salutation);
            cdMap.put('firstName', acc.FirstName);
            cdMap.put('middleName', acc.MiddleName);
            cdMap.put('lastName', acc.LastName);
            cdMap.put('gender', acc.Gender__pc);
            cdMap.put('dateOfBirth', acc.PersonBirthdate);
            cdMap.put('maritalStatus', acc.MaritalStatus__pc);
            cdMap.put('passportNumber', acc.PassportNumber__pc);
            cdMap.put('passportType', acc.Passport_type__pc);
            cdMap.put('passportPlaceOfIssue', acc.PlaceofIssue__pc);
            cdMap.put('passportIssueDate', acc.PassportIssueDate__pc);
            cdMap.put('passportExpiryDate', acc.PassportExpiryDate__pc);
            cdMap.put('visaNo', acc.VisaUIDNo__pc);
            cdMap.put('visaExpiry', acc.VisaExpiryDate__pc);
            cdMap.put('nationality', acc.Nationality__pc);
            cdMap.put('nationalIdNumber', acc.NationalIdNumber__pc);
            cdMap.put('nationalIdExpiry', acc.NationalIdExpiryDate__pc);
            cdMap.put('homatCardNo', acc.Homatcardnumber__pc);
            cdMap.put('company', acc.Company__pc);   // need to check by Venu
            cdMap.put('companyName', acc.Company__pc);   // need to check by Venu
            cdMap.put('uaeFamilyNo', acc.UaeFamilyNumber__pc);
            cdMap.put('uaeFamilyBookNo', acc.UaeFamilyBookNumber__pc);
            cdMap.put('uaeFbPlaceOfIssue', acc.UaeFamilyBookPlaceofIssue__pc);
            cdMap.put('uaeFbIssueDate', acc.UaeFamilyBookDateofIssue__pc);
            cdMap.put('customerSegment', acc.CustomerType__c);   // List Of Values | by Venu
            cdMap.put('residencyStatus', acc.ResidentStatus__pc == 'Non-Resident' ? 'Non - Resident' : acc.ResidentStatus__pc);   // List Of Values | by Venu
            cdMap.put('employementStatus', acc.EmploymentStatus__pc);
            cdMap.put('purposeOfInvestment', '');   // need to check by Venu
            cdMap.put('smartPass', acc.SmartPass__pc);
            cdMap.put('unifiedNo', acc.UnifiedNumber__c);
            cdMap.put('loyalty', acc.Loyalty__c);
            cdMap.put('classification', acc.CustomerSubType__c);   // List Of Values | by Venu
            cdMap.put('partyId', acc.ERPID__c);
            cdMap.put('createdByUser', String.isBlank(acc.ERPID__c) ? acc.CreatedBy.Email : acc.Owner.Email);
            // cdMap.put('createdByUser', 'VPAWAR');
            cdMap.put('sourceOfFunds', acc.SourceofFunds__pc);
            cdMap.put('otherSoruceFund', acc.Other_Source_of_Funds__pc);
            cdMap.put('positionTitle', acc.Position__pc);

            //Pass compound field as a trimmed string.
            String workplaceAddress = acc.Workplace_Street__pc + ' ,'+ acc.Workplace_Country__pc + ' ,'+ acc.Workplace_Postalcode__pc;
            String trimmedWorkplaceAddress = workplaceAddress != null ? workplaceAddress.substring(0, Math.min(99, workplaceAddress.length())) : '';
            cdMap.put('companyAddress', trimmedWorkplaceAddress);
            cdMap.put('annualTotalIncome', String.valueOf(acc.AnnualIncome__pc));
            cdMap.put('noOfYearsWithCompany', String.valueOf(acc.NoofYearswithCompany__pc));
            cdMap.put('natureOfBusiness', acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT ? acc.Industry : '');   // List Of Values | by Venu
            cdMap.put('emailP', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.Email__c : acc.PersonEmail);
            cdMap.put('phoneLineTypeP', 'MOBILE');   // List Of Values // need to change
            cdMap.put('phoneCountryCodeP', mobileCountryCode);
            cdMap.put('phoneAreaCodeP', '');
            cdMap.put('phoneNumberP', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.MobileNumber1__c : acc.MobilePhone__pc);
            cdMap.put('phoneExtensionP', '');
            cdMap.put('countryP', billingCountry);//added by Nikhil
            cdMap.put('address1P', acc.BillingStreet);
            cdMap.put('address2P', '');
            cdMap.put('address3P', '');
            cdMap.put('address4P', '');
            cdMap.put('cityP', acc.BillingCity);
            cdMap.put('postalCodeP', acc.BillingPostalCode);
            cdMap.put('stateP', acc.BillingState);
            cdMap.put('provinceP', '');
            cdMap.put('countyP', '');
            cdMap.put('countyCode', mobileCountryCode); // Added by vamshi || it will take picklist value of country code selected
            cdMap.put('emailS', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.Email__c : acc.PersonEmail);
            cdMap.put('phoneLineTypeS', 'MOBILE');   // List Of Values // need to change
            cdMap.put('phoneCountryCodeS', mobileCountryCode);
            cdMap.put('phoneAreaCodeS', '');
            cdMap.put('phoneNumberS', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.MobileNumber1__c : acc.MobilePhone__pc);
            cdMap.put('phoneExtensionS', '');
            cdMap.put('countryS', String.isNotBlank(acc.ShippingCountry) ? acc.ShippingCountry : '');
            cdMap.put('address1S', acc.ShippingStreet);
            cdMap.put('address2S', '');
            cdMap.put('address3S', '');
            cdMap.put('address4S', '');
            cdMap.put('cityS', acc.ShippingCity);
            cdMap.put('postalCodeS', acc.ShippingPostalCode);
            cdMap.put('stateS', acc.ShippingState);
            cdMap.put('provinceS', '');
            cdMap.put('countyS', '');
            cdMap.put('eidPlaceofIssuance', acc.EIDPlaceofissuance__c != null ? acc.EIDPlaceofissuance__c : '');
            
            Map<String, Object> oIds = new Map<String, Object>();
            if (acc.OtherERPID__c != null) {
                oIds = (Map<String, Object>)JSON.deserializeUntyped(acc.OtherERPID__c);
                for (String key: oIds.keySet()) {
                    oIds.put(key.toLowerCase(), oIds.get(key));
                }
            }
            cdMap.put('partySiteIdP', !oIds.isEmpty() && oIds.containsKey('partysiteidp') ? String.valueOf(oIds.get('partysiteidp')) : '');
            cdMap.put('partySiteUseIdP', !oIds.isEmpty() && oIds.containsKey('partysiteuseidp') ? String.valueOf(oIds.get('partysiteuseidp')) : '');
            cdMap.put('contactPointIdPhoneP', !oIds.isEmpty() && oIds.containsKey('contactpointidphonep') ? String.valueOf(oIds.get('contactpointidphonep')) : '');
            cdMap.put('contactPointIdEmailP', !oIds.isEmpty() && oIds.containsKey('contactpointidemailp') ? String.valueOf(oIds.get('contactpointidemailp')) : '');
            cdMap.put('locationIdP', !oIds.isEmpty() && oIds.containsKey('locationidp') ? String.valueOf(oIds.get('locationidp')) : '');
            cdMap.put('partySiteIdS', !oIds.isEmpty() && oIds.containsKey('partysiteids') ? String.valueOf(oIds.get('partysiteids')) : '');
            cdMap.put('partySiteUseIdS', !oIds.isEmpty() && oIds.containsKey('partysiteuseids') ? String.valueOf(oIds.get('partysiteuseids')) : '');
            cdMap.put('contactPointIdPhoneS', !oIds.isEmpty() && oIds.containsKey('contactpointidphones') ? String.valueOf(oIds.get('contactpointidphones')) : '');
            cdMap.put('contactPointIdEmailS', !oIds.isEmpty() && oIds.containsKey('contactpointidemails') ? String.valueOf(oIds.get('contactpointidemails')) : '');
            cdMap.put('locationIdS', !oIds.isEmpty() && oIds.containsKey('locationids') ? String.valueOf(oIds.get('locationids')) : '');

            cdList.add(cdMap);
        }
        finalMap.put('customerDetails', cdList);
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replaceAll(':null', ':""');
        System.debug('requestBody>>>' + requestBody);
        
        if (!cdList.isEmpty() && System.isFuture() == false && otherObjectIds.isEmpty()) {
            if (System.IsBatch() == true) { 
                CalloutToMuleSoft.calloutService(requestBody, true, Constants.CUSTOMER_INTEGRATION, accIds);
            } else {
                CalloutToMuleSoft.calloutFutureService(requestBody, true, Constants.CUSTOMER_INTEGRATION, accIds);
            }
        } else if (!otherObjectIds.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftQueueable(requestBody, true, Constants.CUSTOMER_INTEGRATION, otherObjectIds, objectName));
        }
    }
}