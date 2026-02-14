global without sharing class CC_DigitalSignatureByAuthorizedSignatory implements HexaBPM.iCustomCodeExecutable{
 
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        //START - Agency Registration Target for Broker Managers
        String currentMonth = '';//String.valueOf(Date.Today().Month());
        String currentYear = '';//String.valueOf(Date.Today().Year()); 
        //END - Agency Registration Target for Broker Managers
        try{
 
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_DigitalSignatureByAuthorizedSignatory: Invalid SR or SR Step';

            }else{
                HexaBPM__Service_Request__c sRRecord = [SELECT AccountName__c, HexaBPM__Customer__c, EstablishmentDate__c, TradeCommercialLicenseNumber__c, ExpiryDate__c, PhoneNumber__c, 
                Address1__c, Address2__c, Country__c, State__c, City__c, POBox__c, CompanyEmail__c, 
                TaxRegistrationNumber__c, VATRegistrationStartDate__c, VATRegistrationEndDate__c,VATRegistrationtype__c,
                NameOfPOA__c, BankName__c, IBANNumber__c, BankSortCode__c,
                SwiftCode__c, BankAddress__c, BankAccountNumber__c, BankCountry__c, Website__c, HexaBPM__Required_Docs_not_Uploaded__c, 
                BrokerManager__c, AgencyCategory__c, AgencySubCategory__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c limit 1];

                Account adminAccount = [Select Id, name, EstablishmentDate__c, RegistrationNumber__c, RegistrationExpiryDate__c, 
                Phone, Phone__c, PhoneNumberEnc__c, BillingStreet, BillingCountry, BillingState, BillingCity, BillingPostalCode, 
                Email__c, UAEVATRegisterNumber__c, NameOfPOA__c, BankName__c, IBANNumber__c, SwiftCode__c, BranchAddress__c, 
                BeneficiaryName__c, BankSortCode__c, Website, DateOfRegistration__c, BrokerAgent__c, MobileCountryCode__c, OwnerId, 
                BrokerAgent__r.Email, BrokerAgent__r.Name, ProposedBankAccountNumber__c,ProposedBankCountry__c,ProposedBankName__c,
                ProposedBeneficiaryName__c, ProposedBranchAddress__c,ProposedIBANNumber__c,ProposedSwiftCode__c,ProposedBankDetailStatus__c,
                VATRegistrationtype__c, ProposedVATStartDate__c,ProposedVATExpiryDate__c,ProposedUAEVATRegisterNumber__c,
                ProposedVATRegistrationtype__c FROM Account WHERE Id=:sRRecord.HexaBPM__Customer__c];

                adminAccount.name = sRRecord.AccountName__c;
                adminAccount.EstablishmentDate__c = sRRecord.EstablishmentDate__c;
                adminAccount.RegistrationNumber__c = sRRecord.TradeCommercialLicenseNumber__c;
                adminAccount.RegistrationExpiryDate__c = sRRecord.ExpiryDate__c;
                adminAccount.MobileCountryCode__c = sRRecord.PhoneNumber__c.split(' ').size() > 1 ? sRRecord.PhoneNumber__c.split(' ')[0] : adminAccount.MobileCountryCode__c;
                adminAccount.Phone = sRRecord.PhoneNumber__c.replaceAll('(\\s+)', '');
                adminAccount.Phone__c = sRRecord.PhoneNumber__c.replaceAll('(\\s+)', '');
                adminAccount.PhoneNumberEnc__c =  sRRecord.PhoneNumber__c.replaceAll('(\\s+)', '');
                adminAccount.BillingStreet = sRRecord.Address1__c +' - '+ sRRecord.Address2__c;
                adminAccount.BillingCountry = sRRecord.Country__c;
                adminAccount.BillingState = sRRecord.State__c;
                adminAccount.BillingCity = sRRecord.City__c;
                adminAccount.BillingPostalCode = sRRecord.POBox__c;
                adminAccount.Email__c = sRRecord.CompanyEmail__c;
                adminAccount.UAEVATRegisterNumber__c = sRRecord.TaxRegistrationNumber__c;
                adminAccount.NameOfPOA__c = sRRecord.NameOfPOA__c;
                //Bank Details - START - Bank Country To Be Added
                adminAccount.BankName__c            = sRRecord.BankName__c;
                adminAccount.IBANNumber__c          = sRRecord.IBANNumber__c;
                adminAccount.SwiftCode__c           = sRRecord.SwiftCode__c;
                adminAccount.BranchAddress__c       = sRRecord.BankAddress__c;
                adminAccount.BankAccountNumber__c   = sRRecord.BankAccountNumber__c;
                adminAccount.BankCountry__c         = sRRecord.BankCountry__c;
                adminAccount.BankSortCode__c        = sRRecord.BankSortCode__c;
                //Bank Details - END
                adminAccount.Website = sRRecord.Website__c;
                adminAccount.DateOfRegistration__c = system.today();
                adminAccount.AgencyStatus__c = Constants.ACTIVE;
                
                //Added by Tharun for BPE-180
                adminAccount.AgencyCategory__c = sRRecord.AgencyCategory__c;
                adminAccount.AgencySubCategory__c = sRRecord.AgencySubCategory__c;
               // adminAccount.UAEVATRegisterNumber__c = sRRecord.UAEVATRegisterNumber__c;
                if(sRRecord.BrokerManager__c != null){
                    adminAccount.OwnerId = sRRecord.BrokerManager__c;
                }
                if(sRRecord.HexaBPM__Required_Docs_not_Uploaded__c == false){
                    adminAccount.AMLFlag__c = true;
                } else{
                    adminAccount.AMLFlag__c = false;
                }
                
                // VAT
                adminAccount.ProposedUAEVATRegisterNumber__c = sRRecord.TaxRegistrationNumber__c; 
                adminAccount.ProposedVATStartDate__c = sRRecord.VATRegistrationStartDate__c;
                adminAccount.ProposedVATExpiryDate__c = sRRecord.VATRegistrationEndDate__c;
                adminAccount.ProposedVATRegistrationtype__c = sRRecord.VATRegistrationtype__c;
                if(!Test.isRunningTest()){  adminAccount.VATRegistrationtype__c = sRRecord.VATRegistrationtype__c; }

                update adminAccount;
                
                /*if (adminAccount.ProposedBankName__c != null && adminAccount.ProposedSwiftCode__c != null && 
                    (adminAccount.ProposedBankAccountNumber__c != null || adminAccount.ProposedIBANNumber__c != null) && 
                    adminAccount.ProposedBankDetailStatus__c == 'Pending') {
                    try {
                        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                        approvalRequest.setObjectId(adminAccount.Id);
                        approvalRequest.setSubmitterId(adminAccount.OwnerId);
                        Approval.ProcessResult result1 = Approval.process(approvalRequest);
                    } catch (Exception e) { System.debug('Approval submission failed: ' + e.getMessage()); }
                }

                if(adminAccount.ProposedVATRegistrationtype__c == 'VAT Registration Certificate' && 
                   adminAccount.ProposedVATStartDate__c != null && 
                   adminAccount.ProposedVATExpiryDate__c != null && 
                   adminAccount.ProposedUAEVATRegisterNumber__c != null) {
                       
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    req1.setComments('Documents uploaded for review.');
                    req1.setObjectId(adminAccount.id);
                    req1.setSubmitterId(adminAccount.OwnerId);

                    if(adminAccount.ProposedUAEVATRegisterNumber__c != null) {
                        req1.setProcessDefinitionNameOrId('BrokerUAEVATApproval');
                    }
                    
                    req1.setSkipEntryCriteria(true);
                    if(!Test.isRunningTest()){
                        Approval.ProcessResult result2 = Approval.process(req1);
                    }
                }
                */
                
                //START - Agency Registration Target for Broker Managers                
                try {
                    currentMonth = String.valueOf(adminAccount.DateOfRegistration__c.Month());
                    currentYear = String.valueOf(adminAccount.DateOfRegistration__c.Year());
                    if(sRRecord.BrokerManager__c != null) {
                        List<MonthlySalesTarget__c> mstList = [SELECT Id, Achieved_Number_of_Registrations__c FROM MonthlySalesTarget__c 
                                                               WHERE ResourceName__c=:sRRecord.BrokerManager__c AND TargetMonth__c=:currentMonth 
                                                               AND TargetYear__c=:currentYear Limit 1];
                        //sRRecord.HexaBPM__Customer__c
                        if(!mstList.isEmpty()) {
                            mstList[0].Achieved_Number_of_Registrations__c = mstList[0].Achieved_Number_of_Registrations__c==null ? 1 : mstList[0].Achieved_Number_of_Registrations__c + 1;
                            update mstList[0];
                        }
                    }
                } catch(Exception e) {
                    System.debug('Exception - Agency Registration Target for Broker Managers -> '+e.getMessage()+' -> '+e.getLineNumber());
                }
                //END - Agency Registration Target for Broker Managers // Updated by Moh Sarfaraj for BPM-497
                List<Contact> AdminContact = [SELECT Id, OwnerId FROM Contact WHERE BrokerType__c = :Constants.AGENCY_ADMIN AND AccountId =: adminAccount.Id];
                List<Contact> contactToUpdate = new List<Contact>();
                
                for (Contact contactRec : AdminContact) {
                    if(sRRecord.BrokerManager__c != null){
                        contactRec.OwnerId = sRRecord.BrokerManager__c;
                        // Below line added by Tharun
                        contactRec.AccountOwner__c = sRRecord.BrokerManager__c;
                        contactToUpdate.add(contactRec);
                    }
                }
                
                update contactToUpdate;
                // Updated By Moh Sarfaraj for BPE-110
                List<AgencyTeam__c> partnerOwners = [SELECT Name, Title__c, EmailAddress__c, MobileNumber__c, Nationality__c, Country__c, 
                                                     ServiceRequest__c, ServiceRequest__r.BrokerManager__c, Type__c, PrimaryOwner__c,
                                                     MobileCountryCode__c,PrimaryAgencyAdmin__c, RoleInCompany__c, National_Id__c FROM AgencyTeam__c 
                                                     WHERE ServiceRequest__c =: stp.HexaBPM__SR__c AND Type__c =: Constants.PARTNER_OWNER];
                                                     
                // Updated by Moh Sarfaraj for BPM-497
                List<Contact> newContact = UtilitiesWithoutSharing.createAgencyContact(partnerOwners, adminAccount.Id, Constants.PARTNER_OWNER, true);

                Utilities.updateUserProfile(adminAccount.BrokerAgent__c, Constants.AGENCY_ADMIN_PROFILE_LOGIN);

                List<HexaBPM__SR_Doc__c> srDocsoUpdate = new List<HexaBPM__SR_Doc__c>();

                HexaBPM__SR_Doc__c signedByCCO = new HexaBPM__SR_Doc__c();

                for (HexaBPM__SR_Doc__c srDocRecord : [SELECT Name, Id, HexaBPM__Customer__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =: sRRecord.Id]) {
                    srDocRecord.HexaBPM__Customer__c = adminAccount.Id;
                    srDocsoUpdate.add(srDocRecord);

                    if(Constants.AGENCY_AGREEMENT_SIGNED_BY_CCO_SRDOC.equals(srDocRecord.Name)){
                        signedByCCO = srDocRecord;
                    } else if (Constants.AGENCY_AGREEMENT_SIGNED_BY_HEAD_OF_BROKER_SRDOC.equals(srDocRecord.Name)){
                        signedByCCO = srDocRecord;
                    }
                }
                update srDocsoUpdate;

                system.debug('Point signedByCCO: '+ signedByCCO);

                Map <String, ContentDocumentLink> contentDocMap = new Map<String, ContentDocumentLink>();

                if(signedByCCO != null && signedByCCO.Id != null){
                    for(ContentDocumentLink contentDocumentRecord : [SELECT ContentDocumentId, Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =: signedByCCO.Id]){
                        contentDocMap.put(contentDocumentRecord.ContentDocumentId,contentDocumentRecord);
                    }
                }

                system.debug('Point contentDocMap: '+ contentDocMap);

                if(contentDocMap != null && !contentDocMap.isEmpty()){
                    List<ContentVersion> contentVersionRecords = [SELECT Id, ContentDocumentId, VersionData, Title FROM ContentVersion WHERE ContentDocumentId in : contentDocMap.keySet()];
                
                    system.debug('Point contentVersionRecords: '+ contentVersionRecords);

                    List<Messaging.EmailFileAttachment> emailAttachList = new List<Messaging.EmailFileAttachment>();
                    for(ContentVersion cvObj : contentVersionRecords) {
                        emailAttachList.add(Utilities.setEmailFileAtt(cvObj));            
                    }

                    system.debug('Point emailAttachList: '+ emailAttachList);


                    string htmlData='<body class="setupTab" ><style background-color="#FFFFFF" bEditID="b1st1" bLabel="body" ></style><center ><table cellpadding="0" width="500" cellspacing="0" id="topTable" height="450" ><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r1st1" bLabel="header" vertical-align="top" height="100px" text-align="left" ></style><img border="0" bEditID="r1sp1" bLabel="headerImage" id="r1sp1" src="'+System.Label.CommunicationHeader+'"></img></td></tr><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r2st1" bLabel="accent1" height="5px" ></style>#CONTENT#</td></tr></table></center></body>';

                    Messaging.SingleEmailMessage mail = Utilities.getEmailInstance(null, null, null, new List<String>{adminAccount.BrokerAgent__r.Email}, null, null, 'Your Agency Registration Request is Approved', htmlData.replace('#CONTENT#','Dear '+adminAccount.BrokerAgent__r.Name+',<BR>Your Agency Registration request is Approved.<BR><BR>Warm Regards,<BR>ALDAR PROPERTIES PJSC'), htmlData.replace('#CONTENT#','Dear '+adminAccount.BrokerAgent__r.Name+',<BR>Your Agency Registration request is Approved.<BR><BR>Warm Regards,<BR>ALDAR PROPERTIES PJSC'),emailAttachList, Utilities.getOrgWideEmailAddressId());
                    Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{mail});
                }

                system.debug(adminAccount);
                system.debug(newContact);
                system.debug(srDocsoUpdate);

            } 
       } catch(Exception e){
            result = 'CC_DigitalSignatureByAuthorizedSignatory: ' +  e.getMessage();
        } 
        return result;
    }
}