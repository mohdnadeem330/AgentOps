global without sharing class CC_ReviewRegistrationRequest implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_ReviewRegistrationRequest: Invalid SR or SR Step';
            }else{
                List<HexaBPM__Step__c> oldSteps = [SELECT Id, ExecuteCustomCode__c FROM HexaBPM__Step__c WHERE 
                                                  HexaBPM__SR__c =: stp.HexaBPM__SR__c AND ExecuteCustomCode__c = false];

                if(stp.ExecuteCustomCode__c && (oldSteps == null || oldSteps.isEmpty())){

                    stp.ExecuteCustomCode__c = false;
                    // Updated By Moh Sarfaraj for BPE-322, BPM-357, BPM-550
                    HexaBPM__Service_Request__c sRRecord = [SELECT AccountName__c, EstablishmentDate__c, TradeCommercialLicenseNumber__c, ExpiryDate__c, PhoneNumber__c, 
                    Address1__c, Address2__c, Country__c, State__c, City__c, POBox__c, CompanyEmail__c, TaxRegistrationNumber__c, NameOfPOA__c, BankName__c, IBANNumber__c, 
                    SwiftCode__c, BankAddress__c, BankCountry__c, BankAccountNumber__c, Website__c, HexaBPM__Required_Docs_not_Uploaded__c, BrokerManager__c, HexaBPM__Customer__c,
                    InterestedPropertyLocation__c, FIABCIRegistered__c, FIABCIStatus__c, SubAccountManager__c,
                    AgencyCategory__c, AgencySubCategory__c, TradeLicenseType__c,ReferralSource__c,TradeName__c,TradingAddress__c,OrganizationName__c,BankSortCode__c
                    FROM HexaBPM__Service_Request__c WHERE Id =: stp.HexaBPM__SR__c LIMIT 1];

                    // Added By Moh Sarfaraj for BPM-481 starts
                    String tradeLN = sRRecord?.TradeCommercialLicenseNumber__c?.deleteWhitespace();
                    List<HexaBPM__Service_Request__c> existingSRWithClosedStatus = [SELECT Id,HexaBPM__Customer__c FROM HexaBPM__Service_Request__c 
                                                                              WHERE Id != :sRRecord.Id AND 
                                                                              HexaBPM__External_Status_Name__c = 'Closed' AND HexaBPM__Customer__c != null AND
                                                                              HexaBPM__Customer__r.AgencyStatus__c = 'Closed' AND
                                                                              TradeCommercialLicenseNumber__c = :tradeLN LIMIT 1];
                    
                    Boolean isRequireToCheckExistingContacts = false;
                    Account newAccount = new Account(); 
                    if(existingSRWithClosedStatus != null && !existingSRWithClosedStatus.isEmpty()){newAccount.Id = existingSRWithClosedStatus[0].HexaBPM__Customer__c; isRequireToCheckExistingContacts = true;
                        // what about the new SR info which needs to be update on Account?
                        // What we need to do with Old SR?
                        // What about the existing Agents/ Primary Owner/ Primary Admins
                    }
                    // Added By Moh Sarfaraj for BPM-497 end 

                    // calling to create/update Account/Agency
                    newAccount = AccountService.createBrokerAccount(sRRecord, Constants.PENDING_VERIFICATION, newAccount);
                    // Added By Moh Sarfaraj for BPM-481 end

                    // Updated By Moh Sarfaraj for BPE-110
                    List<AgencyTeam__c> agency = [SELECT Name, Title__c, EmailAddress__c, MobileCountryCode__c, MobileNumber__c, Country__c, 
                                                  Nationality__c,ServiceRequest__c, ServiceRequest__r.BrokerManager__c, Type__c, RoleInCompany__c,
                                                  PrimaryAgencyAdmin__c, PrimaryOwner__c, National_Id__c FROM AgencyTeam__c WHERE 
                                                  ServiceRequest__c =: stp.HexaBPM__SR__c AND 
                                                  Type__c =: Constants.AGENCY_ADMIN LIMIT 1];

                    List<Contact> newContact = UtilitiesWithoutSharing.createAgencyContact(agency, newAccount.Id, Constants.AGENCY_ADMIN, isRequireToCheckExistingContacts);

                    newAccount.BrokerAgent__c = newContact[0].Id;
                    newAccount.IsPartner = true;
                    update newAccount;

                    sRRecord.HexaBPM__Customer__c = newAccount.Id;
                    update sRRecord;

                    update stp;

                    // Added By Moh Sarfaraj for BPM-497   
                    updateUser(newContact[0].Id, isRequireToCheckExistingContacts);
                }
            } 
        } catch(Exception e){
           if(e.getMessage().contains('Duplicate Username')) {result = e.getMessage() + '[ERROR] Cannot enable communities access, a user with this email address already exists.';} 
           else { result = e.getMessage()+' :CC_ReviewRegistrationRequest'; }
        } 
        return result;
    }
 
    @future 
    public static void updateUser(String contactId, Boolean isRequireToCheckExistingContacts){
        // Added By Moh Sarfaraj for BPM-497   
        // Added loggers - by KP
        try{
            if(!isRequireToCheckExistingContacts){
                UtilitiesWithoutSharing.createUserFromContact(contactId, true, Constants.PARTNER_COMMUNITY_USER_LOGIN);
            }else {  //updateUser(newContact[0].Id);
                UtilitiesWithoutSharing.updateExistingCommunityUser(contactId, true, Constants.PARTNER_COMMUNITY_USER_LOGIN);
            }
        }catch(Exception ex){ LoggerService.save(LoggerService.addApexLog(ex,'AgencyRegistration','CC_ReviewRegistrationRequest','updateUser')); }
    }
}