/* This batch will run on daily basis to calculate the actual working time of an agent
 */ 
global class ALD_WorkLogHandlerBatch implements Database.Batchable<sObject>{

    /*global void execute(SchedulableContext sc) {
Database.ExecuteBatch(new ALD_WorkLogHandlerBatch(), 100);
}*/
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //Take all the record related to the todays parent record
         
        String QueryStringVar = 'SELECT Id, Assigned_User__c,Assigned_User__r.Profile.Name,'+ 
            '(SELECT Id, Assigned_Date_and_Time__c, Assigned_User__c, Case__c, Completed_Date_and_Time__c,Service_Request__c, Time_Spent__c, Parent_Work_Log__c '+
            'FROM Child_Work_Logs__r WHERE Completed_Date_and_Time__c!=null order by Assigned_Date_and_Time__c asc)'+
            'FROM ALD_Work_Log__c WHERE Parent_Work_Log__c=null and (CreatedDate = TODAY or CreatedDate = YESTERDAY)'; // CreatedDate = TODAY
        System.debug('##$$ QueryStringVar > '+QueryStringVar);
        
        return Database.getQueryLocator(QueryStringVar);
    }
    
    global void execute(Database.BatchableContext bc, List<ALD_Work_Log__c> scope) {
        List<ALD_Work_Log__c> parWLToUpdate = new List<ALD_Work_Log__c>();
        
        for(ALD_Work_Log__c parWl : scope) {
            //system.debug('Assigned User:'+parWl);
            //system.debug('Assigned User:'+parWl.Assigned_User__c);
             //system.debug('Assigned User:'+parWl.Assigned_User__r.Profile.Name);
            String BusinessHoursId = parWl.Assigned_User__r.Profile.Name == ALD_WorkLogHelper.CONTACT_CENTER_AGENT ? ALD_WorkLogHelper.CCA_BusinessHoursId : ALD_WorkLogHelper.CM_BusinessHoursId;
                       
            DateTime PrevChildStartTime = null;
            DateTime PrevChildEndTime = null;
            Integer SumOfTimeToBeInParent = 0;
            System.debug('parWl.Child_Work_Logs__r size > '+parWl.Child_Work_Logs__r.size());
            for(ALD_Work_Log__c chldWl : parWl.Child_Work_Logs__r) {
                DateTime newStartTime = chldWl.Assigned_Date_and_Time__c; //1 // 2.30
                DateTime newEndTime = chldWl.Completed_Date_and_Time__c; //2.30 // 3.30
                //System.debug('##### chldWl -> '+chldWl.Id);
                //System.debug('##### newEndTime -> '+newEndTime+' > '+chldWl.Id);
                Long diffTime = null;
                Long OverlappingTime = null;
                //System.debug('##### PrevChildStartTime -> '+PrevChildStartTime);
                
                System.debug('##IF parWl.Id > '+parWl.Id+' || chldWl.Id = '+chldWl.Id);

                if(PrevChildStartTime == null) {
                    diffTime = BusinessHours.diff(BusinessHoursId,newStartTime, newEndTime); //CCA_BusinessHoursId needs to be dynamic
                    SumOfTimeToBeInParent = Integer.valueOf(diffTime);
                    System.debug('##IF 0 SumOfTimeToBeInParent > '+chldWl.Id+' >> '+SumOfTimeToBeInParent+' > NS = '+newStartTime+' > NE = '+newEndTime);
                } else {
                    System.debug('##IF 000 SumOfTimeToBeInParent > '+SumOfTimeToBeInParent);

                    diffTime = BusinessHours.diff(BusinessHoursId,newStartTime, newEndTime);//CCA_BusinessHoursId needs to be dynamic
                    System.debug('##IF 1 diffTime > '+diffTime);

                    //if(PrevChildEndTime 11 AM >= newStartTime 10.30 && PrevChildEndTime 11 AM >=newEndTime 10.30 AM) ? 0 : PrevChildEndTime (11 AM) - newEndTime (11.30 AM) : 
                    //System.debug('PrevChildEndTime > '+PrevChildEndTime);
                    //System.debug('newStartTime > '+newStartTime);
                    //System.debug('newEndTime > '+newEndTime);
                    System.debug('##IF 010 > '+PrevChildEndTime+' >= '+newStartTime+' > is valid > ');
                    System.debug('##IF 020 > '+PrevChildEndTime+' >= '+newEndTime+' > is valid > ');
                    System.debug('##IF 030 > '+PrevChildEndTime+' <= '+newEndTime+' > is valid > ');
                    if(PrevChildEndTime >= newStartTime && PrevChildEndTime >= newEndTime) {
                        SumOfTimeToBeInParent = SumOfTimeToBeInParent + 0; //Integer.valueOf(diffTime); //1.30 + (2.30-3.30) = 2.30
                        System.debug('##IF 2 SumOfTimeToBeInParent > '+SumOfTimeToBeInParent);
                    } else if(PrevChildEndTime >= newStartTime && PrevChildEndTime <= newEndTime) {
                        diffTime = BusinessHours.diff(BusinessHoursId,PrevChildEndTime, newEndTime);//if 9AM>=8AM && 9AM<=9.15, then we need to calculate only the 15 mins. as we are taking the child in asc order, newstart time will not be lesser than prev start time
                        SumOfTimeToBeInParent = SumOfTimeToBeInParent + Integer.valueOf(diffTime); //1.30 + (2.30-3.30) = 2.30
                        System.debug('##IF 3 SumOfTimeToBeInParent > '+SumOfTimeToBeInParent+' > diffTime = '+diffTime);
                    } else {
                        OverlappingTime = BusinessHours.diff(BusinessHoursId,newStartTime, PrevChildEndTime);//CCA_BusinessHoursId needs to be dynamic
                        SumOfTimeToBeInParent = SumOfTimeToBeInParent + Integer.valueOf(diffTime) - Integer.valueOf(OverlappingTime); // 2.30 + (3-5) - .30 = 4;
                        System.debug('##IF 4 SumOfTimeToBeInParent > '+SumOfTimeToBeInParent+' > NS = '+newStartTime+' > PCET = '+PrevChildEndTime);
                    }
                }
                //Capture the previous time always
                PrevChildStartTime = chldWl.Assigned_Date_and_Time__c;
                PrevChildEndTime = PrevChildEndTime >= newEndTime ? PrevChildEndTime : newEndTime; //3:39 PM >= 9:44 AM
            }
            System.debug('##IF Last SumOfTimeToBeInParent -> '+SumOfTimeToBeInParent);

            parWl.Pr_Time_Spent_Today__c = SumOfTimeToBeInParent;
            parWLToUpdate.add(parWl);
        }
        
        if(parWLToUpdate.size()>0) {
            update parWLToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
}