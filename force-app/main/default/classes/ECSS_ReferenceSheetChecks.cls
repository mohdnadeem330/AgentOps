public without sharing class ECSS_ReferenceSheetChecks {
    
    public class FlowInputs{
        @InvocableVariable(label= 'Occupant Details Collection')
        public List<ECSS_OccupantDetails> occupantDetails;
        @InvocableVariable(label='Related Account')
        public Id relatedAccount;
        @InvocableVariable(label= 'Last Names Collection')
        public List<String> lastNames;
        @InvocableVariable(label= 'National Ids Collection')
		public List<String> nationalIds;
		@InvocableVariable(label= 'Passport Numbers Collection')
		public List<String> passportNumbers;
		@InvocableVariable(label= 'Last Name And Passport Collection')
		public List<String> lastNameAndPassport;
		@InvocableVariable(label= 'Last Name And National Id Collection')
		public List<String> lastNameAndNationalId;
    }
    
    
    @InvocableMethod(label='Check For Duplicate Accounts')
    public static void checkForDuplicateAccounts(List<FlowInputs> flowInputs)
    {
        //This method is to check for the duplicate accounts before creating them for the co occupants
        
        //The following Lists are to get the list of (names, passport number and national Ids) entered for all the co occupants
        List<String> lastNames = flowInputs[0].lastNames;
        List<String> nationalIds = flowInputs[0].nationalIds;
        List<String> passportNumbers = flowInputs[0].passportNumbers;
        
        //The following lists are to get the combination of both the last name with the passport and last name with national Id
        List<String> lastNameAndPassport = flowInputs[0].lastNameAndPassport;
        List<String> lastNameAndNationalId = flowInputs[0].lastNameAndNationalId;
        
        //The account Id is the main account that is for the main occupant
        Id accountId = flowInputs[0].relatedAccount;
        List<ECSS_OccupantDetails>  occupantDetails = flowInputs[0].occupantDetails;
        System.debug('flowInputs[0].occupantDetails: '+flowInputs[0].occupantDetails);
        System.debug('flowInputs[0].relatedAccount: '+flowInputs[0].relatedAccount);
        System.debug('occupantDetails: '+occupantDetails);
        System.debug('accountId: '+accountId);
        System.debug('flowInputs[0].lastNames: '+flowInputs[0].lastNames);
        System.debug('flowInputs[0].nationalIds: '+flowInputs[0].nationalIds);
        System.debug('flowInputs[0].passportNumbers: '+flowInputs[0].passportNumbers);
        System.debug('flowInputs[0].lastNameAndPassport: '+flowInputs[0].lastNameAndPassport);
        System.debug('flowInputs[0].lastNameAndNationalId: '+flowInputs[0].lastNameAndNationalId);
        
        //Get the Person Account Record type to create the new co occupant accounts 
        Id personAccountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        Map<String,Id> duplicateAccounts = new Map<String,Id>(); //This map is used to capture the duplicate accounts with their unique lastname and passport or lastname and national id 
        Map<Id,AccountRelationship__c> existingAccountRelationships = new Map<Id,AccountRelationship__c>(); //This map is used to capture the existing account relationship records available
        
        //The following maps and Lists are used to capture the records that will be upserted and inserted
        Map <String,Account> accountsToUpsert = new Map<String,Account>();
        List <AccountRelationship__c> accountRelationshipsToUpsert = new List<AccountRelationship__c>();
        List <ECSS_Occupant__c> occupantToInsert = new List<ECSS_Occupant__c>();
        
        //Fetch the existing accounts and loop on them to get the unique last name and passport or last name and national id combination
        //Map the combination with the account Id.
        List<Account> existingAccounts = [SELECT Id,FirstName,LastName,NationalIdNumber__pc,PassportNumber__pc FROM Account WHERE LastName IN :lastNames AND (NationalIdNumber__pc IN :nationalIds OR PassportNumber__pc IN :passportNumbers)];
        for(Account acc: existingAccounts){
            if(acc.NationalIdNumber__pc!= null && acc.NationalIdNumber__pc!='')
            {
                duplicateAccounts.put(acc.LastName+' '+acc.NationalIdNumber__pc,acc.Id);
            }
            else if(acc.PassportNumber__pc!=null && acc.PassportNumber__pc!='')
            {
                duplicateAccounts.put(acc.LastName+' '+acc.PassportNumber__pc,acc.Id);
            }
        }
        //Fetch the existing Account Relationship records and map the existing account relationship records with the existing account Ids
        List<AccountRelationship__c> existingRelationships = [SELECT Id,Account__c ,RelatedAccount__c FROM AccountRelationship__c WHERE RelatedAccount__c =:accountId AND Account__c IN :duplicateAccounts.values()];
        for(AccountRelationship__c accRel: existingRelationships)
        {
            existingAccountRelationships.put(accRel.Account__c, accRel);
        }
        //Loop on the Occupant Details provided by the user
        for(ECSS_OccupantDetails occ: occupantDetails){
            String tempNameAndPassport = occ.lastName + ' '+ occ.passportNumber;
            String tempNameAndNationalId = occ.lastName+ ' '+occ.nationalId;
            Account tempAccount = new Account();
            
            //Check if the occupant exists
            //Check using the last name and passport combination
            if(duplicateAccounts.containsKey(tempNameAndPassport))
            {
                tempAccount.Id = duplicateAccounts.get(tempNameAndPassport);
                tempAccount.PassportNumber__pc = occ.passportNumber;
                tempAccount.MobileCountryCode__pc =occ.mobileCountryCode;
                tempAccount.PersonMobilePhone = occ.mobileNumber;
                tempAccount.PersonBirthdate = occ.dateOfBirth;
                tempAccount.PersonEmail = occ.email;
                tempAccount.NationalIdNumber__pc = occ.nationalId;
                Set<String> values = new Set<String>();
                if (String.isNotBlank(tempAccount.CustomerVertical__c)) {
                    values.addAll(tempAccount.CustomerVertical__c.split(';'));
                }
                values.add('Aldar Estates');
                tempAccount.CustomerVertical__c = String.join(new List<String>(values), ';');
                accountsToUpsert.put(tempNameAndPassport,tempAccount);
            }
            //Check uding the last name and national Id combination
            else if(duplicateAccounts.containsKey(tempNameAndNationalId))
            {
                tempAccount.Id = duplicateAccounts.get(tempNameAndNationalId);
                tempAccount.PassportNumber__pc = occ.passportNumber;
                tempAccount.MobileCountryCode__pc =occ.mobileCountryCode;
                tempAccount.PersonMobilePhone = occ.mobileNumber;
                tempAccount.PersonBirthdate = occ.dateOfBirth;
                tempAccount.PersonEmail = occ.email;
                tempAccount.NationalIdNumber__pc = occ.nationalId;
                accountsToUpsert.put(tempNameAndNationalId,tempAccount);
            }
            // if the account does not exist then create the account record with the details that should be inserted
            else
            {
                String tempKey = occ.lastName + ' '+ occ.passportNumber + ' '+ occ.nationalId;
                tempAccount.RecordTypeId = personAccountRecTypeId;
                tempAccount.PassportNumber__pc = occ.passportNumber;
                tempAccount.MobileCountryCode__pc =occ.mobileCountryCode;
                tempAccount.PersonMobilePhone = occ.mobileNumber;
                tempAccount.PersonBirthdate = occ.dateOfBirth;
                tempAccount.PersonEmail = occ.email;
                tempAccount.NationalIdNumber__pc = occ.nationalId;
                tempAccount.FirstName = occ.firstName;
                tempAccount.LastName = occ.lastName;
                tempAccount.CustomerVertical__c = 'Aldar Estates';
                accountsToUpsert.put(tempKey,tempAccount);
            }
            
        }
        //Upsert all the captured data to update the existing accounts and insert the new accounts.
        try{
            upsert accountsToUpsert.values();
        }
        catch(Exception e)
        {
            System.debug('Exception: '+e.getMessage());
        }
        //Loop on the Occupant details to create the account relationship and occupant records
        for(ECSS_OccupantDetails occ:occupantDetails){
            String tempNameAndPassport = occ.lastName + ' '+ occ.passportNumber;
            String tempNameAndNationalId = occ.lastName+ ' '+occ.nationalId;
            String tempNameAndPassportAndNationalId = occ.lastName + ' '+ occ.passportNumber + ' '+ occ.nationalId;
            AccountRelationship__c tempRelationship = new AccountRelationship__c();
            ECSS_Occupant__c tempOccupant = new ECSS_Occupant__c();
            
            //Check if the account relationship records exist
            //Check using the last name and Passport number combination
            if(existingAccountRelationships.containsKey(duplicateAccounts.get(tempNameAndPassport)))
            {
                tempRelationship.Id = existingAccountRelationships.get(duplicateAccounts.get(tempNameAndPassport)).Id;
                tempRelationship.RelationshipSubType__c = occ.relationship;
                if(tempRelationship.RelatedAccount__c != tempRelationship.Account__c)
                    accountRelationshipsToUpsert.add(tempRelationship);
                tempOccupant.ECSS_Co_Occupant_Account__c = duplicateAccounts.get(tempNameAndPassport);
            }
            //Check using the last name and national Id combination
            else if(existingAccountRelationships.containsKey(duplicateAccounts.get(tempNameAndNationalId)))
            {
                tempRelationship.Id = existingAccountRelationships.get(duplicateAccounts.get(tempNameAndNationalId)).Id;
                tempRelationship.RelationshipSubType__c = occ.relationship;
                if(tempRelationship.RelatedAccount__c != tempRelationship.Account__c)
                 accountRelationshipsToUpsert.add(tempRelationship);
                tempOccupant.ECSS_Co_Occupant_Account__c = duplicateAccounts.get(tempNameAndNationalId);            
            }
            //Create the account relationship records that will be inserted
            else
            {
                if(accountsToUpsert.containsKey(tempNameAndPassport))
                {
                    tempRelationship.Account__c = accountsToUpsert.get(tempNameAndPassport).Id;
                    tempOccupant.ECSS_Co_Occupant_Account__c = accountsToUpsert.get(tempNameAndPassport).Id;
                }
                else if(accountsToUpsert.containsKey(tempNameAndNationalId))
                {
                    tempRelationship.Account__c = accountsToUpsert.get(tempNameAndNationalId).Id;
                    tempOccupant.ECSS_Co_Occupant_Account__c = accountsToUpsert.get(tempNameAndNationalId).Id;
                }
                else
                {
                    tempRelationship.Account__c = accountsToUpsert.get(tempNameAndPassportAndNationalId).Id;
                    tempOccupant.ECSS_Co_Occupant_Account__c = accountsToUpsert.get(tempNameAndPassportAndNationalId).Id;
                }
                tempRelationship.RelatedAccount__c = accountId;
                tempRelationship.RelationshipType__c = 'Third Party';
                tempRelationship.RelationshipSubType__c = occ.relationship;
                if(tempRelationship.RelatedAccount__c != tempRelationship.Account__c)
                 accountRelationshipsToUpsert.add(tempRelationship);
            }
            //Create the occupant records to be inserted
            tempOccupant.ECSS_Asset__c = occ.assetId;
            tempOccupant.ECSS_Quote__c = occ.quoteId;
            tempOccupant.ECSS_Occupant_Account__c = accountId;
            tempOccupant.ECSS_Opportunity__c = occ.opportunityId;
            if(tempOccupant.ECSS_Occupant_Account__c != tempOccupant.ECSS_Co_Occupant_Account__c  )
             occupantToInsert.add(tempOccupant);
            
        }
        try{
            //Upsert the account relationship to update the existing account relationship records and to insert the new account relationship records
            upsert accountRelationshipsToUpsert;
            //Insert the new Occupant records
            insert occupantToInsert;
        }
        catch(Exception e)
        {
            System.debug('Exception: '+e.getMessage());
        }
    }
}