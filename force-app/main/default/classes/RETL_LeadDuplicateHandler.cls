/**
 * RETL_LeadDuplicateHandler
 * --------------------------
 * Invocable Apex class to find potential duplicate records (Contacts, Accounts, Opportunities)
 * for a given list of Lead Ids. 
 *
 * Duplicates are checked via:
 *   • Salesforce Duplicate Management (Datacloud.FindDuplicates)
 *   • Trade License number matches
 *
 * Key Responsibilities:
 *   • Accepts a list of Lead Ids as input
 *   • Returns duplicate Contacts and Accounts per Lead
 *   • Sets flags indicating if duplicates exist
 *   • Provides placeholders for related Opportunities
 *
 * @author  vkotaprolu@aldar.com
 * @date    2025-11-19
 */
public with sharing class RETL_LeadDuplicateHandler {

    /**
     * Request class
     * Input wrapper for Invocable Method.
     */
    public class Request {
        @InvocableVariable(required=true)
        public Id leadId; // Lead Id to check for duplicates
    }

    /**
     * Response class
     * Output wrapper for Invocable Method.
     */
    public class Response {
        @InvocableVariable
        public List<Contact> contacts; // List of duplicate Contacts found

        @InvocableVariable
        public List<Account> accounts; // List of duplicate Accounts found

        @InvocableVariable
        public List<Opportunity> opportunities; // List of related Opportunities found

        @InvocableVariable
        public Boolean hasDuplicateContacts;  // Flag indicating if duplicate Contacts were found

        @InvocableVariable
        public Boolean hasDuplicateAccounts; // Flag indicating if duplicate Accounts were found
    }

    /**
     * Invocable Method
     * Finds duplicate Contacts, Accounts, and Opportunities for the given Lead Id(s).
     *
     * @param requests - List of Request objects containing Lead Ids
     * @return List<Response> - List of Response objects containing duplicates and related Opportunities
     */
    @InvocableMethod(
        label='Find Lead Duplicates' 
        description='Find matching Contacts, Accounts, and Related Opportunities for given Lead Ids'
    )
    public static List<Response> findLeadDuplicates(List<Request> requests) {
        List<Response> resultsList = new List<Response>();

        if (requests.isEmpty()) {
            return resultsList;
        }

        // Step 1: Collect Lead Ids
        Set<Id> leadIds = new Set<Id>();
        for (Request req : requests) {
            if (req.leadId != null) {
                leadIds.add(req.leadId);
            }
        }

        // Step 2: Query all Leads at once
        Map<Id, Lead> leadMap = new Map<Id, Lead>([
            SELECT Id, Name, Email, Company, RETL_Trade_License_No__c 
            FROM Lead 
            WHERE Id IN :leadIds
        ]);

        // Step 3: Run duplicate check for all Leads at once
        List<Lead> leadList = new List<Lead>(leadMap.values());
        Map<Id, List<Contact>> leadToContacts = new Map<Id, List<Contact>>();
        Map<Id, List<Account>> leadToAccounts = new Map<Id, List<Account>>();

        Set<Id> allAccountIds = new Set<Id>();
        Set<Id> allContactIds = new Set<Id>();

        if (!leadList.isEmpty()) {
            Datacloud.FindDuplicatesResult[] dupResults = Datacloud.FindDuplicates.findDuplicates(leadList);

            for (Integer i = 0; i < dupResults.size(); i++) {
                Id currentLeadId = leadList[i].Id;
                List<Contact> cList = new List<Contact>();
                List<Account> aList = new List<Account>();

                for (Datacloud.DuplicateResult dr : dupResults[i].getDuplicateResults()) {
                    for (Datacloud.MatchResult mr : dr.getMatchResults()) {
                        for (Datacloud.MatchRecord record : mr.getMatchRecords()) {
                            SObject dupRecord = record.getRecord();

                            if (dupRecord instanceof Contact) {
                                Contact c = (Contact)dupRecord;
                                cList.add(c);
                                allContactIds.add(c.Id);
                                if (c.AccountId != null) {
                                    allAccountIds.add(c.AccountId);
                                }
                            } else if (dupRecord instanceof Account) {
                                Account a = (Account)dupRecord;
                                aList.add(a);
                                allAccountIds.add(a.Id);
                            }
                        }
                    }
                }

                leadToContacts.put(currentLeadId, cList);
                leadToAccounts.put(currentLeadId, aList);
            }
        }

        // 🔹 Step 4: Query full Account records
        Map<Id, Account> accountMap = new Map<Id, Account>();
        if (!allAccountIds.isEmpty()) {
            accountMap = new Map<Id, Account>([
                SELECT Id, Name, RecordTypeName__c, Type,
                       ECSS_Trade_License_Number__c,
                       RETL_Trade_License_Issuing_Authority__c,
                       RETL_Group__c, AccountLink__c
                FROM Account
                WHERE Id IN :allAccountIds LIMIT 200
            ]);
        }

        // 🔹 Step 5: Query full Contact records (added fix)
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        if (!allContactIds.isEmpty()) {
            contactMap = new Map<Id, Contact>([
                SELECT Id, FirstName, LastName, Email, AccountId,
                       RecordTypeId, RecordType.Name, RecordType.DeveloperName,RecordTypeName__c
                FROM Contact
                WHERE Id IN :allContactIds LIMIT 200
            ]);
        }

        // Step 6: Build responses per request
        for (Request req : requests) {
            Response res = new Response();

            res.contacts = new List<Contact>();
            if (leadToContacts.containsKey(req.leadId)) {
                for (Contact cStub : leadToContacts.get(req.leadId)) {
                    if (contactMap.containsKey(cStub.Id)) {
                        res.contacts.add(contactMap.get(cStub.Id));
                    }
                }
            }

            res.accounts = new List<Account>();
            if (leadToAccounts.containsKey(req.leadId)) {
                for (Account accStub : leadToAccounts.get(req.leadId)) {
                    if (accountMap.containsKey(accStub.Id)) {
                        res.accounts.add(accountMap.get(accStub.Id));
                    }
                }
            }

            res.opportunities = new List<Opportunity>(); // placeholder

            // Set hasDuplicates flags
            res.hasDuplicateContacts = !res.contacts.isEmpty();
            res.hasDuplicateAccounts = !res.accounts.isEmpty();

            resultsList.add(res);
        }

        return resultsList;
    }
}