public class ECSS_CaseMilestoneController {
    
    @AuraEnabled(cacheable=true)
    public static Integer getCaseTotalResolution(String caseId)
    {
        AggregateResult[] groupedResults= [Select Max(TargetResponseInHrs)max from CaseMilestone where CaseId=:caseId];
        if(groupedResults.size()>0)
        return Integer.ValueOf(groupedResults[0].get('max'));
        else return null;
        //List<Case> caseList = new List<Case>([Select ECSS_Total_Resolution_Time__c from Case where Id=:caseId Limit 1]);
       /* system.debug('Case'+caseList);
        if(caseList.size()>0)
        {
            system.debug('ddd'+Integer.valueOf(caseList[0].ECSS_Total_Resolution_Time__c));
            return Integer.valueOf(caseList[0].ECSS_Total_Resolution_Time__c);
        }
        else return null;*/
    }
    
    @AuraEnabled(cacheable=true)
    public static List<MSDetailsWrapper> milestoneDetails(String inpCaseId){
        
        
        List<MSDetailsWrapper> output = new List<MSDetailsWrapper>();
        
        
        List<CaseMilestone> milestones = [SELECT TargetDate, TargetResponseInMins, TargetResponseInHrs
                                          FROM CaseMilestone
                                          WHERE caseId=: inpCaseId
                                          ORDER BY TargetResponseInMins asc
                                         ];
        system.debug(milestones);
       // Id functionalLocationRecTypeId =Utilities.getRecordTypeId('Asset',Constants.ECSSFunctionalLocation);
        
        List<Case> recCase = new List<Case>([SELECT id,
                        ECSS_Object_Category__c,
                        CaseCategory__c,AssetId,
                        asset.ECSS_Unit_Code__c ,
                        Asset.RecordTypeId, ECSS_Sub_Category_Text__c 
                        FROM case where id =: inpCaseId]);
        
       /* String baseQuery = 'SELECT Site__c,' + 
            'Category__c,Object_Category__c,Email_Template__c,' +
            'Functional_Location__c, Response_Team__c,' +
            'Escalation_Level_1__c, Escalation_Level_2__c, Escalation_Level_3__c' +
            ' FROM ECSS_Case_Assignment_SLA__c WHERE ';
        
        
        List<String> conditions = new List<String>();
        
        if(recCase.Asset.RecordTypeId == functionalLocationRecTypeId)
        {
            String fl = recCase.asset.ECSS_Unit_Code__c;
            conditions.add('Functional_Location__c =: fl');
        }
        else if(recCase.asset.ECSS_Unit_Code__c!=null) {
            String tmpProj = recCase.asset.ECSS_Unit_Code__c.Substring(0,4);
            system.debug(tmpProj);
            conditions.add('Site__c  =: tmpProj'); 
        }
        
        //Save initial criteria and baseQuery
        String baseQueryTemp = baseQuery;
        List<String> TempConditions = new List<String>();
        for(String currTmpCon : conditions){
            TempConditions.add(currTmpCon);
        }
        
        String currObjectCatgory = recCase.ECSS_Object_Category__c;
        system.debug(currObjectCatgory);
        conditions.add('Object_Category__c =:currObjectCatgory');
        
        //Combine conditions
        if (!conditions.isEmpty()) {
            baseQuery += String.join(conditions, ' AND ');
        } else {
            baseQuery = baseQuery.removeEnd(' WHERE '); // Remove trailing 'WHERE' if no conditions exist
        }
        System.debug('query:'+baseQuery);
        List<ECSS_Case_Assignment_SLA__c> mdtList = Database.query(baseQuery);
        
        if(mdtList.size() == 0) {
            baseQuery = baseQueryTemp;
            System.debug('baseQueryTemp:'+baseQueryTemp);
            conditions = TempConditions;
            String tmpCat = recCase.CaseCategory__c;
            conditions.add('Category__c =:tmpCat');
            
            //Combine conditions
            if (!conditions.isEmpty()) {
                baseQuery += String.join(conditions, ' AND ');
            } else {
                baseQuery = baseQuery.removeEnd(' WHERE '); // Remove trailing 'WHERE' if no conditions exist
            } 
            
            System.debug('baseQuery'+baseQuery);
            mdtList = Database.query(baseQuery);       
        }
        
        
        if(mdtList.isEmpty()){
            mdtList = [SELECT Site__c,
            Category__c,Object_Category__c,Email_Template__c,
            Functional_Location__c, Response_Team__c,
            Escalation_Level_1__c, Escalation_Level_2__c, Escalation_Level_3__c
            FROM ECSS_Case_Assignment_SLA__c WHERE Category__c=:recCase.CaseCategory__c];
            System.debug('entered here');
        }*/
        List<ECSS_CaseAssignmentReturn> caseSLAList = ECSS_CaseAssiggnmentSLAFromMtd.getAllEscalationEmails(recCase);
        
        Integer counter = 1;
       String escalationName;
        for(CaseMilestone MSList : milestones) {
            system.debug('COUNTER'+counter);
            String escEmail = '';
            if(caseSLAList.size()>0)
            {
                if(counter == 1){
                    escEmail= caseSLAList[0].Escalation_Email_1;
                    escalationName = caseSLAList[0].EscalationName;
                }
                
                else if(counter == 2) {
                    escEmail= caseSLAList[0].Escalation_Email_2;
                    escalationName = caseSLAList[0].EscalationName2;
                }
                
                else {
                    escEmail= caseSLAList[0].Escalation_Email_3;
                    escalationName = caseSLAList[0].EscalationName3;
                }
                counter ++ ;
            }
            
            
            
            MSDetailsWrapper temp = new MSDetailsWrapper(MSList.TargetDate , 
                                                         MSList.TargetResponseInMins,
                                                         MSList.TargetResponseInHrs,
                                                         escEmail,
                                                         EscalationName
                                                        );
            
            output.add(temp);
        }
        
        
        return output;
        
    }
    public class MSDetailsWrapper {
        @AuraEnabled 
        public DateTime TargetDate { get; set; }
        @AuraEnabled 
        public Double TargetResponseInMins { get; set; }
         @AuraEnabled 
        public Double TargetResponseInHrs { get; set; }
        @AuraEnabled 
        public String EscalationEmail { get; set; }
        @AuraEnabled 
        public String EscalationName { get; set; }
        
        
        public MSDetailsWrapper (DateTime TargetDate,Double TargetResponseInMins,Decimal TargetResponseInHrs, String EscalationEmail, String EscalationName) {
            this.TargetDate = TargetDate;
            this.TargetResponseInMins = TargetResponseInMins;
            this.TargetResponseInHrs = TargetResponseInHrs;
            this.EscalationEmail = EscalationEmail;
            this.EscalationName = EscalationName;
        }
    }
    
}