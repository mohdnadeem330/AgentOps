@IsTest
private class com_getRelatedAccountsAndContacts_Test {
    
    @IsTest
    static void testGetRelatedAccountsAndContacts() {
        
        // Get RT ids
        Id personRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        Id orgRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('OrganizationAccount')
            .getRecordTypeId();
        
        System.assertNotEquals(null, personRtId,
                               'Test requires a Person Account Record Type in this org.');
        
        // ----- Person parent + related Accounts -----
        Account parentPerson = new Account(
            RecordTypeId = personRtId,
            LastName     = 'Parent Person'
        );
        insert parentPerson;
        
        Account childAcc1 = new Account(Name = 'Child Account 1');
        Account childAcc2 = new Account(Name = 'Child Account 2');
        insert new List<Account>{ childAcc1, childAcc2 };
            
            // IMPORTANT: in your new logic:
            // RelatedAccount__c = parent (main)
            // Account__c       = child
            AccountRelationship__c rel1 = new AccountRelationship__c(
                RelatedAccount__c   = parentPerson.Id,   // parent
                Account__c          = childAcc1.Id,      // child
                RelationshipType__c = 'Third Party',
                RelationshipSubType__c = 'Spouse'        // allowed
            );
        AccountRelationship__c rel2 = new AccountRelationship__c(
            RelatedAccount__c   = parentPerson.Id,   // parent
            Account__c          = childAcc2.Id,      // child
            RelationshipType__c = 'Third Party',
            RelationshipSubType__c = 'POA'           // EXCLUDED by NOT IN
        );
        insert new List<AccountRelationship__c>{ rel1, rel2 };
            
            // ----- Org parent + related Contacts -----
            Account orgParent = new Account(
                RecordTypeId = orgRtId,
                Name         = 'Org Parent'
            );
        insert orgParent;
        
        // Primary account for contacts (to avoid private-contact issue)
        Account accForContact = new Account(Name = 'Acc for contact');
        insert accForContact;
        
        Contact con1 = new Contact(
            FirstName = 'John',
            LastName  = 'Doe',
            AccountId = accForContact.Id
        );
        Contact con2 = new Contact(
            FirstName = 'Jane',
            LastName  = 'Smith',
            AccountId = accForContact.Id
        );
        insert new List<Contact>{ con1, con2 };
            
            AccountContactRelation acr1 = new AccountContactRelation(
                AccountId = orgParent.Id,
                ContactId = con1.Id
            );
        AccountContactRelation acr2 = new AccountContactRelation(
            AccountId = orgParent.Id,
            ContactId = con2.Id
        );
        insert new List<AccountContactRelation>{ acr1, acr2 };
            
            // ----- Call Invocable method -----
            com_getRelatedAccountsAndContacts.FlowInput inputPerson =
            new com_getRelatedAccountsAndContacts.FlowInput();
        inputPerson.parentAccountId = parentPerson.Id;
        
        com_getRelatedAccountsAndContacts.FlowInput inputOrg =
            new com_getRelatedAccountsAndContacts.FlowInput();
        inputOrg.parentAccountId = orgParent.Id;
        
        List<com_getRelatedAccountsAndContacts.FlowInput> inputs =
            new List<com_getRelatedAccountsAndContacts.FlowInput>{
                inputPerson,
                    inputOrg
                    };
                        
                        Test.startTest();
        List<com_getRelatedAccountsAndContacts.FlowOutput> outputs =
            com_getRelatedAccountsAndContacts.getRelatedForFlow(inputs);
        
        List<com_getRelatedAccountsAndContacts.FlowOutput> emptyOutputs =
            com_getRelatedAccountsAndContacts.getRelatedForFlow(
                new List<com_getRelatedAccountsAndContacts.FlowInput>()
            );
        Test.stopTest();
        
        // ----- Assertions -----
        System.assertEquals(2, outputs.size(),
                            'Should return one FlowOutput per FlowInput.');
        
        // 1) Person Account output: related Accounts only
        com_getRelatedAccountsAndContacts.FlowOutput personOutput = outputs[0];
        
        // With the new logic + NOT IN filter, only childAcc1 (Spouse) should be returned.
        System.assertEquals(1, personOutput.relatedAccounts.size(),
                            'Person parent should have 1 related Account (excluding Broker/Owner/POA).');
        
        Set<Id> personRelatedAccIds = new Set<Id>();
        for (Account a : personOutput.relatedAccounts) {
            personRelatedAccIds.add(a.Id);
        }
        System.assert(personRelatedAccIds.contains(childAcc1.Id),
                      'childAcc1 should be included as related Account.');
        System.assert(!personRelatedAccIds.contains(childAcc2.Id),
                      'childAcc2 should be excluded because of RelationshipSubType__c = POA.');
        
        System.assertEquals(0, personOutput.relatedContacts.size(),
                            'Person parent should not return related Contacts.');
        
        // 2) Org Account output: related Contacts only
        com_getRelatedAccountsAndContacts.FlowOutput orgOutput = outputs[1];
        
        System.assertEquals(0, orgOutput.relatedAccounts.size(),
                            'Org parent should not return related Accounts (IsPersonAccount = false).');
        System.assertEquals(2, orgOutput.relatedContacts.size(),
                            'Org parent should return 2 related Contacts.');
        
        Set<Id> orgRelatedContactIds = new Set<Id>();
        for (Contact c : orgOutput.relatedContacts) {
            orgRelatedContactIds.add(c.Id);
        }
        System.assert(orgRelatedContactIds.contains(con1.Id),
                      'con1 should be included as related Contact.');
        System.assert(orgRelatedContactIds.contains(con2.Id),
                      'con2 should be included as related Contact.');
        
        // 3) Empty input list → no outputs
        System.assertEquals(0, emptyOutputs.size(),
                            'Empty input list should return an empty result list.');
    }
}