@isTest(SeeAllData=false)
public class DashboardWebserviceTest {
    @isTest static void setupData() {
        
        User user = TestObjectsFactory.getUserRecord('System Administrator', 'ajaythakur');
        user.IsActive = TRUE;
        insert user;
        
        

        System.runAs(user)
        {
            
            User salesManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM');
            salesManager.IsActive = TRUE;
            insert salesManager;
            
            RoundRobinAssignmentMatrix__c rrRecord = TestObjectsFactory.getAssignmentRecord(salesManager.Id);
            insert rrRecord;
            System.debug(userInfo.getUserId());
            
            Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'1232344');
            insert personAcc;
            
            Account agencyAccount = TestObjectsFactory.getAgencyAccountRecord('Agency', '1234');
            insert agencyAccount;
            
            Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
            insert orgAcc;
            
            Contact brokerContact = TestObjectsFactory.contactDataSetup(agencyAccount.Id);
            
            Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAcc.Id);
            opportunityRecord.AgentType__c = Constants.OPPORTUINTY_AGENT_TYPE_INDIRECT;
            opportunityRecord.StageName = Constants.STAGE_MEETING;
            opportunityRecord.StageName = 'Bank';
            opportunityRecord.BrokerAgencyAccount__c = agencyAccount.Id;
            opportunityRecord.BrokerAgentContact__c = brokerContact.Id;
            insert opportunityRecord;
            
            Opportunity opportunityRecord1 = TestObjectsFactory.getOpportunityRecord(orgAcc.Id);
            opportunityRecord1.StageName = Constants.STAGE_CLOSEDWON;
            opportunityRecord1.AgentType__c = Constants.OPPORTUINTY_AGENT_TYPE_DIRECT;            
            insert opportunityRecord1;
            
            Project__c project = TestObjectsFactory.getProjectRecord('ABC');
            insert project;
            
            Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
            unit.Project__c = project.Id;
            unit.Name = 'MAYAN-B1-101095';
            insert unit;
            
            SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opportunityRecord1.Id, orgAcc.Id);
            salesOrder.Unit__c = unit.Id;
            salesOrder.IsBookingCompleted__c = true;
            salesOrder.BookingDate__c = date.today();
            salesOrder.status__c = Constants.SO_STATUS_SOLD;
            salesOrder.SalesManager__c = userInfo.getUserId();
            
            insert salesOrder;
            
            
            // Create Lead From Account Record
            Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
            leadRec.ExistingAccount__c = personAcc.Id;
            leadRec.IsCreateFromExistingAccount__c = true;
            leadRec.PropertyUsage__c = Constants.RESIDENTIAL_LEASE;
            leadRec.BuyRent__c = 'Rent' ;
            leadRec.SalesType__c = Constants.ASSET_MANAGEMENT;
            leadRec.Project__c = 'Al Zeina';
            leadRec.CustomerBudget__c=null;
            insert leadRec;
            
            Task task1 = TestObjectsFactory.getLeadActivity(leadRec.ID);
            task1.Status = 'Completed';
            task1.CustomerResponse__c = Constants.CUSTOMER_REACHED;
            task1.ReminderDateTime = system.now() + 1;
            task1.OwnerId = UserInfo.getUserId();
            task1.TaskType__c = Constants.TASK_TYPE_DAY1;
            task1.Subject = Constants.TASK_TYPE_DAY1;
            update task1;
            
            Task task = TestObjectsFactory.getLeadActivity(leadRec.ID);

            MonthlySalesTarget__c monthlySalesTarget = TestObjectsFactory.getMonthlySalesTargetRecord(salesManager.Id, Constants.USER_TEAM_DXB);
            monthlySalesTarget.TargetAmount__c = 10000;
            //monthlySalesTarget.ResourceName__c = user.id;
            insert monthlySalesTarget;
        }
        
        RoundRobinAssignmentUtility.setAgentAvailable(new set<ID>{userInfo.getUserId()});
        RoundRobinAssignmentUtility.getAgentAvailibility(new set<ID>{userInfo.getUserId()});
        TestObjectsFactory.initializeRestContext(null, '/homepage/dashboard');
        DashboardWebservice.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        
        DashboardWebservice.doPost();
        
        Test.stopTest();
        
    }
    
}