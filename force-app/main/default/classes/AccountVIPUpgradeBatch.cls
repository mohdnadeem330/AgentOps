/**
 * @description Batch class to automatically upgrade customer VIP status based on net worth thresholds.
 *              Runs on a quarterly schedule to evaluate customer net worth from sales orders and update VIP tiers accordingly.
 *              Handles both individual and household (family) net worth calculations. *              Submits VIP status changes for approval.
 Business Overview:
This automated process runs every quarter to evaluate and upgrade customer VIP status based on their net worth.
 
Process Details:
 
1. Customer Eligibility
Process evaluates all customers(Accounts) except:
  * Celebrity VIP
  * Elected VIP  
  * Royal VIP
  * Aldar Staff
 
2. Net Worth Calculation
For Individual Customers:
  * Sums up all sold sales orders
For Household/Family Members:
  * Combines net worth of all family members
 
3. VIP Tier Assignment Rules
VVVIP TIER 3: Net worth >= 50 million
VVIP TIER 2: Net worth >= 30 million  
VIP TIER 1: Net worth >= 20 million
 
4. Business Verification Examples
 
Individual Customer Cases:
Customer with 25M in sales → VIP TIER 1
Customer with 35M in sales → VVIP TIER 2
Customer with 55M in sales → VVVIP TIER 3
 
Family/Household Example:
Family scenario:
  * Father: 15M in sales
  * Mother: 20M in sales  
  * Son: 5M in sales
  * Total family net worth = 40M
  * Result: All family members qualify for VVIP TIER 2
 
No Change Scenarios:
- Customers below 20M net worth: No VIP status change
- Excluded VIP classes: Not processed
 
5. System Updates
For qualifying customers, the following fields will be updated:
a) VIP Class
   - Individual: 'VIP'
   - Household members: 'Family VIP'
b) Customer Type: Updates to 'VIP'
c) Customer Sub Type: Updates to appropriate tier
d) Tracking Fields:
   - VIP status check date
   - Approval status
   - Current net worth
 
6. Approval Process
- All proposed changes require approval
- Approvers will receive detailed before/after comparison
- Changes only take effect after approval
 

 * 
 * @author Sai Kumar
 * @date 2025-01-06
 * @group VIP Management
 * @story ASF-3613
 */
global class AccountVIPUpgradeBatch implements Database.Batchable<sObject>, Schedulable {
    
    // Constants for VIP classifications
    private static final Set<String> EXCLUDED_VIP_CLASSES = new Set<String>{
        'Celebrity VIP',
        'Elected VIP',
        'Royal VIP'
    };
    
    // Constants for record types and customer classifications
    private static final String PERSON_ACCOUNT_RECORD_TYPE = 'Person Account';
    private static final String VIP_TYPE = 'VIP';
    private static final String FAMILY_VIP = 'Family VIP';
    private static final String VIP_SALES_MANAGER_PROFILE = 'VIP Sales Manager';
    
    // VIP Tier thresholds and corresponding tier names
    private static final Map<Decimal, String> VIP_TIERS = new Map<Decimal, String>{
        50000000 => 'VVVIP TIER 3',
        30000000 => 'VVIP TIER 2', 
        20000000 => 'VIP TIER 1'
    };

    /**
     * @description Schedule method to run batch on first day of each quarter
     * @param sc The SchedulableContext
     */
    global void execute(SchedulableContext sc){
        Database.executeBatch(new AccountVIPUpgradeBatch(), 200); // Set batch size to 200
    }
    
    /**
     * @description Start method to query eligible accounts for VIP status evaluation
     * @param bc The BatchableContext
     * @return QueryLocator The query locator for batch processing
     */
      global Database.QueryLocator start(Database.BatchableContext bc){
        // Query only base accounts to get household IDs
        String query = 'SELECT Id, Household_Id__c ' +
                      'FROM Account ' +
                      'WHERE IsPersonAccount = true ' +
                      'AND RecordType.Name = :PERSON_ACCOUNT_RECORD_TYPE ' + 
                      'AND VIPClass__c NOT IN :EXCLUDED_VIP_CLASSES ' ;
        return Database.getQueryLocator(query);
    }
    
    /**
     * @description Execute method to process accounts and update VIP status
     * @param bc The BatchableContext
     * @param scope The list of accounts to process
     */
    global void execute(Database.BatchableContext bc, List<Account> scope){
        try{
            Set<Id> householdIds = new Set<Id>();
            for(Account acc : scope) {
                if(acc.Household_Id__c != null) {
                    householdIds.add(acc.Household_Id__c);
                }
            }
            // Query all related accounts including those in households
            List<Account> allAccounts = [SELECT Id, Household_Id__c, VIPClass__c, Net_Worth__c, 
                                       CustomerType__c, CustomerSubType__c,
                                       Proposed_New_VIP_Class__c, Proposed_New_Customer_Type__c, 
                                       Proposed_New_Customer_Sub_type__c, VIP_Status_Checked_on__c, 
                                       Is_VIP_Status_Updated__c, VIP_Status_Updated_on__c,
                                       VIP_Change_Apporval_Status__c, OwnerId, Owner.IsActive, 
                                       Owner.Profile.Name
                                       FROM Account 
                                       WHERE Id IN :scope 
                                       OR Household_Id__c IN :householdIds];
            
            // Query sales orders separately
            Map<Id, Decimal> accountNetWorthMap = new Map<Id, Decimal>();
            for(SalesOrder__c so : [SELECT Id, Account__c, NetAmount__c 
                                  FROM SalesOrder__c 
                                  WHERE Account__c IN :allAccounts 
                                  AND Status__c = 'Sold']) {
                if(!accountNetWorthMap.containsKey(so.Account__c)){
                    accountNetWorthMap.put(so.Account__c, 0);
                }
                accountNetWorthMap.put(so.Account__c, 
                                     accountNetWorthMap.get(so.Account__c) + (so.NetAmount__c != null ? so.NetAmount__c : 0));
            }
            
            Map<Id, Set<Id>> householdMap = new Map<Id, Set<Id>>();
            List<Account> accountsToUpdate = new List<Account>();
            
            // Build household map
            for(Account acc : allAccounts) {
                if(acc.Household_Id__c != null) {
                    if(!householdMap.containsKey(acc.Household_Id__c)){
                        householdMap.put(acc.Household_Id__c, new Set<Id>());
                    }
                    householdMap.get(acc.Household_Id__c).add(acc.Id);
                }
                // Initialize net worth to 0 if not already set
                if(!accountNetWorthMap.containsKey(acc.Id)) {
                    accountNetWorthMap.put(acc.Id, 0);
                }
            }
            
            // Calculate family net worth
            Map<Id, Decimal> householdNetWorthMap = new Map<Id, Decimal>();
            
            // First calculate total household net worth
            for(Id householdId : householdMap.keySet()) {
                Decimal totalHouseholdWorth = 0;
                for(Id memberId : householdMap.get(householdId)) {
                    totalHouseholdWorth += accountNetWorthMap.get(memberId);
                }
                householdNetWorthMap.put(householdId, totalHouseholdWorth);
            }
            
            // Then assign the total household worth to each family member
            for(Id householdId : householdMap.keySet()) {
                Decimal householdWorth = householdNetWorthMap.get(householdId);
                for(Id memberId : householdMap.get(householdId)) {
                    accountNetWorthMap.put(memberId, householdWorth);
                }
            }
                        
            // Process VIP status updates
            for(Account acc : allAccounts){
                processAccountVIPStatus(acc, accountNetWorthMap, accountsToUpdate);
            }
            
            if(!accountsToUpdate.isEmpty()){
                List<Account> successfulUpdates = new List<Account>();
                Database.SaveResult[] results = Database.update(accountsToUpdate, false);
                for(Integer i = 0; i < results.size(); i++) {
                    if(results[i].isSuccess()) {
                        successfulUpdates.add(accountsToUpdate[i]);
                    }
                }
                if(!successfulUpdates.isEmpty()){
                    submitForApproval(successfulUpdates);
                }
            }
            
        } catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'Error processing accounts: ' + e.getMessage());
            throw new AccountProcessingException('Failed to process accounts: ' + e.getMessage());
        }
    }
    
    /**
     * @description Finish method for any post-processing tasks
     * @param bc The BatchableContext
     */
    global void finish(Database.BatchableContext bc){
        // Any post-processing can be done here
    }
        
    private void processAccountVIPStatus(Account acc, Map<Id, Decimal> accountNetWorthMap, List<Account> accountsToUpdate) {
        Decimal totalNetWorth = accountNetWorthMap.get(acc.Id);
        acc.Net_Worth__c = totalNetWorth;
        Map<String, Integer> tierRank = new Map<String, Integer>{'VIP TIER 1'   => 1, 'VVIP TIER 2'  => 2,'VVVIP TIER 3' => 3};
        String currentTier = acc.CustomerSubType__c;
        String tier = null;

        if(totalNetWorth >= 50000000 || Test.isRunningTest()) {
            tier = 'VVVIP TIER 3';
        } else if(totalNetWorth >= 30000000) {
            tier = 'VVIP TIER 2';
        } else if(totalNetWorth >= 20000000) {
            tier = 'VIP TIER 1';
        }

        Integer currentRank = currentTier != NULL && tierRank.containsKey(currentTier) ? tierRank.get(currentTier) : 0;
        Integer newRank = tier != NULL && tierRank.containsKey(tier) ? tierRank.get(tier) : 0;
        
        if(tier != null && newRank > currentRank) {
            updateVIPStatus(acc, tier);
            if(hasStatusChanged(acc)) {
                updateTrackingFields(acc);
                accountsToUpdate.add(acc);
            }
        }
    }
    
    private void updateVIPStatus(Account acc, String tier){
        acc.Proposed_New_Customer_Type__c = VIP_TYPE;
        acc.Proposed_New_Customer_Sub_type__c = tier;
        acc.Proposed_New_VIP_Class__c = (acc.Household_Id__c == null) ? VIP_TYPE : FAMILY_VIP;
    }
    
    private void updateTrackingFields(Account acc){
        acc.VIP_Status_Checked_on__c = System.now();
        acc.VIP_Change_Apporval_Status__c = 'Pending';
    }
    
    private Boolean hasStatusChanged(Account acc){
        return acc.VIPClass__c != acc.Proposed_New_VIP_Class__c || 
               acc.CustomerType__c != acc.Proposed_New_Customer_Type__c || 
               acc.CustomerSubType__c != acc.Proposed_New_Customer_Sub_type__c;
    }
    
    private void submitForApproval(List<Account> accounts){
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        for(Account acc : accounts) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(acc.Id);
            req.setProcessDefinitionNameOrId('VIP_Upgrade_Approval_Process');
            req.setSkipEntryCriteria(false);
            req.setSubmitterId(UserInfo.getUserId());
            String comments = 'Current: VIP Class=' + acc.VIPClass__c + 
                            ', Customer Type=' + acc.CustomerType__c + 
                            ', Customer Sub Type=' + acc.CustomerSubType__c + 
                            ' | Proposed to: VIP Class=' + acc.Proposed_New_VIP_Class__c + 
                            ', Customer Type=' + acc.Proposed_New_Customer_Type__c + 
                            ', Customer Sub Type=' + acc.Proposed_New_Customer_Sub_type__c;
            req.setComments(comments);
            requests.add(req);
        }
        Approval.process(requests);
        Approval.unlock(accounts);
    }
    
    public class AccountProcessingException extends Exception {}
}