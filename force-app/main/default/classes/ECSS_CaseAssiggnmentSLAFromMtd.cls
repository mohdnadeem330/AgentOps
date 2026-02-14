public class ECSS_CaseAssiggnmentSLAFromMtd {
    
    public static List<ECSS_CaseAssignmentReturn> getAllEscalationEmails (List<Case> caseList)
    {
        Set<Id> assetIds = new Set<Id>();
        for(Case caseObj: caseList)
        {
            assetIds.add(caseObj.AssetId);
        }
        List<ECSS_CaseAssignmentReturn> caseReturnList = new List<ECSS_CaseAssignmentReturn>();
        caseReturnList.addAll(ECSS_CaseAssiggnmentSLAFromMtd.getProjectMetadata('GetEmails',assetIds,caseList));
        return caseReturnList;
        
    }
    
    @InvocableMethod
    public static List<ECSS_CaseAssignmentReturn> getFirstEscalationEmail (List<Case> caseList)
    {	
        Set<Id> assetLevel1 = new Set<Id>();
        Set<Id> assetLevel2 = new Set<Id>();
        Set<Id> assetLevel3 = new Set<Id>();
        List<Case> caseLevel1 = new List<Case>();
        List<Case> caseLevel2 = new List<Case>();
        List<Case> caseLevel3 = new List<Case>();

        

        for(Case caseObj: caseList)
        {
            
            //assetIds.add(caseObj.AssetId);
            if(caseObj.ECSS_LatestEscalationLevel__c == 1)
            {	assetLevel1.add(caseObj.AssetId);
             caseLevel1.add(caseObj);
            }
            else if(caseObj.ECSS_LatestEscalationLevel__c == 2)
            {
                assetLevel2.add(caseObj.AssetId);
                caseLevel2.add(caseObj);
            }
            else if (caseObj.ECSS_LatestEscalationLevel__c == 3)
            {
                assetLevel3.add(caseObj.AssetId);
                caseLevel3.add(caseObj);
            }
            
        }
        List<ECSS_CaseAssignmentReturn> caseReturnList = new List<ECSS_CaseAssignmentReturn>();
        caseReturnList.addAll(ECSS_CaseAssiggnmentSLAFromMtd.getProjectMetadata('First Escalation',assetLevel1,caseLevel1));
        caseReturnList.addAll(ECSS_CaseAssiggnmentSLAFromMtd.getProjectMetadata('Second Escalation',assetLevel2,caseLevel2));
        caseReturnList.addAll(ECSS_CaseAssiggnmentSLAFromMtd.getProjectMetadata('Third Escalation',assetLevel3,caseLevel3));
        
        
        return caseReturnList;
    }
    
    
    
    public static List<ECSS_CaseAssignmentReturn> getProjectMetadata(String action,Set<Id>assetIds,List<sObject>newList)
    {
        List<Asset> ecssUnitList = [SELECT RecordType.DeveloperName,
                                    ECSS_Unit_Code__c FROM Asset where Id in:assetIds];
        
        Id functionalLocationRecTypeId =Utilities.getRecordTypeId('Asset',Constants.ECSSFunctionalLocation);
        
        Map<Id,Asset> assetMap = new Map<Id,Asset>();
        for(Asset ecssUnit : ecssUnitList)
        {
            assetMap.put(ecssUnit.Id,ecssUnit);
        }
        List<String> caseObjectCategory = new List<String>();
        List<String> caseCategory = new List<String>();
        for(Case caseRecord : (List<Case>)newList)
        {
            if(caseRecord.ECSS_Object_Category__c!=null){
                caseObjectCategory.add(caseRecord.ECSS_Object_Category__c);
            }
            if(caseRecord.CaseCategory__c!=null){
                caseCategory.add(caseRecord.CaseCategory__c);
            }
        }
        List<ECSS_Case_Assignment_SLA__c> pcaList = new List<ECSS_Case_Assignment_SLA__c >([SELECT Site__c,Escalation_Name__c ,Active_Email__c,
                                                                                            Category__c,Object_Category__c,Email_Template__c,Employee_Name_L3__c,Employee_Name_L2__c,
                                                                                            Functional_Location__c,Sub_Category__c,
                                                                                            Response_Team__c,Escalation_Level_1__c,
                                                                                            Escalation_Level_2__c, Escalation_Level_3__c,
                                                                                            SLA_Level_1__c, SLA_Level_2__c, SLA_Level_3__c,
                                                                                            Owner_Queue_Name__c
                                                                                            FROM ECSS_Case_Assignment_SLA__c where 
                                                                                            (Category__c in:caseCategory or 
                                                                                             Object_Category__c in:caseObjectCategory)]);
        
        Map<String,List<ECSS_Case_Assignment_SLA__c> > site_FunctionalObjectMap = new Map<String,List<ECSS_Case_Assignment_SLA__c> >();
        Map<String,List<ECSS_Case_Assignment_SLA__c> > site_FunctionalCatMap = new Map<String,List<ECSS_Case_Assignment_SLA__c> >();
        Map<String,List<ECSS_Case_Assignment_SLA__c> > catMap = new Map<String,List<ECSS_Case_Assignment_SLA__c> >();
        Set<String> ownerEmails = new Set<String>();
        Set<String> queueNames = new Set<String>();
        String actionField='';
        List<ECSS_Case_Assignment_SLA__c> site_FunctionalObjectList;
        List<ECSS_Case_Assignment_SLA__c> site_FunctionalCatList;
        List<ECSS_Case_Assignment_SLA__c> catList;
        String site_FunctionalObjKeyStr;
        String site_FunctionalCatKeyStr;
        //Map<String,String> ObjectMap = new Map<String,String>();
        for(ECSS_Case_Assignment_SLA__c pCA : pcaList)
        {	
            if(action == 'Owner')
            {
                ownerEmails.add(pca.Response_Team__c);
                queueNames.add(pca.Owner_Queue_Name__c);
            }
            
            // fill map with all Functional Location/Site and Object Category Combinations
            if(pCA.Functional_Location__c!=null && pca.Object_Category__c!=null)
                site_FunctionalObjKeyStr = pCA.Functional_Location__c+'|'+pca.Object_Category__c;
            else if(pCA.Site__c!=null && pca.Object_Category__c!=null)
                site_FunctionalObjKeyStr = pCA.Site__c+'|'+pca.Object_Category__c;
            if(site_FunctionalObjectMap.containsKey(site_FunctionalObjKeyStr))
            {
                site_FunctionalObjectMap.get(site_FunctionalObjKeyStr).add(pCA);
            }
            else
            {
                site_FunctionalObjectList = new List<ECSS_Case_Assignment_SLA__c>();
                site_FunctionalObjectList.add(pCA);
                site_FunctionalObjectMap.put(site_FunctionalObjKeyStr,site_FunctionalObjectList);
            }
            //-----------
            // fill map with all Functional Location/Site and Category Combinations
            if(pCA.Functional_Location__c!=null && pca.Category__c!=null)
                site_FunctionalCatKeyStr = pCA.Functional_Location__c+'|'+pca.Category__c;
            else if(pCA.Site__c!=null && pca.Category__c!=null)
                site_FunctionalCatKeyStr = pCA.Site__c+'|'+pca.Category__c;
            
            if(site_FunctionalCatMap.containsKey(site_FunctionalCatKeyStr))
            {
                site_FunctionalCatMap.get(site_FunctionalCatKeyStr).add(pCA);
            }
            else
            {
                site_FunctionalCatList = new List<ECSS_Case_Assignment_SLA__c>();
                site_FunctionalCatList.add(pCA);
                site_FunctionalCatMap.put(site_FunctionalCatKeyStr,site_FunctionalCatList);
            }
            // if no Functional Location or Site found then fill with Category only
            if(pCA.Functional_Location__c==null && pCA.Site__c==null )
            {
                if(catMap.containsKey(pCA.Category__c))
                {
                    catMap.get(pCA.Category__c).add(pCA);
                }
                else
                {
                    catList = new List<ECSS_Case_Assignment_SLA__c>();
                    catList.add(pCA);
                    catMap.put(pCA.Category__c,catList);
                }
            }
        }
        
        List<User> userList = new List<User>([SELECT Id,Email from User where Email in :ownerEmails]);
        Map<String,Id>userMap = new Map<String,Id>();
        for(User userObj : userList)
        {
            userMap.put(userObj.Email.toLowerCase(),userObj.Id);
        }
        List<Group> queueList = new List<Group>([SELECT Id, DeveloperName from Group where Type = 'Queue' and DeveloperName in :queueNames]);
        
        Map<String,Id>queueMap = new Map<String,Id>();
        for(Group grpObj : queueList)
        {
            queueMap.put(grpObj.DeveloperName.toLowerCase(),grpObj.Id);
        }
        Boolean mtdFound;
        Boolean queueFound;
        string site_FunctionalCode ='';
        string siteCode = '';
        Map<id,String> caseEscalationMap = new Map<Id,String>();
        
        List<ECSS_CaseAssignmentReturn> caseReturnList = new List<ECSS_CaseAssignmentReturn>();
        ECSS_CaseAssignmentReturn car;
        ECSS_Case_Assignment_SLA__c selectedCaseSLA;
        
        Id ECSSQueriesRecordTypeId = Utilities.getRecordTypeId('Case',Constants.ECSSQueries);
        Id ECSSComplaintsRecordTypeId = Utilities.getRecordTypeId('Case',Constants.ECSSComplaints);
        for(Case caseRecord : (List<Case>)newList) {
            mtdFound = false;
            queueFound = false;
            
            if(assetIds.contains(caseRecord.AssetId)){
                
                if(assetMap.containsKey(caseRecord.AssetId) && assetMap.get(caseRecord.AssetId).ECSS_Unit_Code__c!=null)
                {
                    //if attached unit is Functional Location then check records by Functional Location   
                    if(assetMap.get(caseRecord.AssetId).RecordTypeId == functionalLocationRecTypeId){
                        site_FunctionalCode	= assetMap.get(caseRecord.AssetId).ECSS_Unit_Code__c;
                        if(site_FunctionalCode == null){
                            siteCode = assetMap.get(caseRecord.AssetId).ECSS_Unit_Code__c.Substring(0,4);                            
                        }
                    }
                    
                    else // if attached unit is Not Functional Location then check records by first 4 characters of unit code 
                        site_FunctionalCode = assetMap.get(caseRecord.AssetId).ECSS_Unit_Code__c.Substring(0,4);
                    siteCode = assetMap.get(caseRecord.AssetId).ECSS_Unit_Code__c.Substring(0,4);
                    if(site_FunctionalObjectMap.containsKey(site_FunctionalCode+'|'+caseRecord.ECSS_Object_Category__c) 
                       || site_FunctionalObjectMap.containsKey(siteCode+'|'+caseRecord.ECSS_Object_Category__c))
                    {	
                        List<ECSS_Case_Assignment_SLA__c> ecaList = site_FunctionalObjectMap.get(siteCode+'|'+caseRecord.ECSS_Object_Category__c);
                        if(site_FunctionalObjectMap.containsKey(site_FunctionalCode+'|'+caseRecord.ECSS_Object_Category__c)){
                            ecaList = site_FunctionalObjectMap.get(site_FunctionalCode+'|'+caseRecord.ECSS_Object_Category__c);
                        }
                        for(ECSS_Case_Assignment_SLA__c eca :ecaList )
                        {
                            if(eca.Sub_Category__c!=null && eca.Sub_Category__c == caseRecord.ECSS_Sub_Category_Text__c)
                            {
                                //subCategoryFound = true;
                                selectedCaseSLA = eca;
                                break;
                            }
                            else if(eca.Sub_Category__c == null)
                                selectedCaseSLA = eca; 
                            
                        }
                        
                        if(selectedCaseSLA!=null)
                        {    
                            if(action == 'Owner')
                            {
                                if(queueMap.containsKey(selectedCaseSLA.Owner_Queue_Name__c.toLowerCase()))
                                {
                                    caseRecord.OwnerId = queueMap.get(selectedCaseSLA.Owner_Queue_Name__c.toLowerCase());
                                    caseRecord.ECSS_Assigned_by_Project_Metadata__c = true;
                                    queueFound = true;
                                }
                                /* if(userMap.containsKey(selectedCaseSLA.Response_Team__c.toLowerCase()))
{
caseRecord.OwnerId = userMap.get(selectedCaseSLA.Response_Team__c.toLowerCase());
caseRecord.ECSS_Assigned_by_Project_Metadata__c = true;
}*/
                                if(caseRecord.RecordTypeId == ECSSComplaintsRecordTypeId || (caseRecord.RecordTypeId == ECSSQueriesRecordTypeId && !caseRecord.FCR__c))
                                {
                                    caseRecord.ECSS_LatestEscalationLevel__c = 0;
                                    caseRecord.ECSS_SLA_Level_1__c = selectedCaseSLA.SLA_Level_1__c;
                                    caseRecord.ECSS_SLA_Level_2__c = selectedCaseSLA.SLA_Level_2__c;
                                    caseRecord.ECSS_SLA_Level_3__c = selectedCaseSLA.SLA_Level_3__c;

                                }
                                
                            }
                            else if(action=='GetEmails')
                            {
                                car = new ECSS_CaseAssignmentReturn();
                                car.caseId = caseRecord.Id;

                                car.ResponseTeam =  selectedCaseSLA.Response_Team__c;
                                car.Escalation_Email_1 =selectedCaseSLA.Escalation_Level_1__c;
                                car.Escalation_Email_2 = selectedCaseSLA.Escalation_Level_2__c;
                                car.Escalation_Email_3 = selectedCaseSLA.Escalation_Level_3__c;
                                car.EscalationName = selectedCaseSLA.Escalation_Name__c;
                                car.EscalationName2 = selectedCaseSLA.Employee_Name_L2__c;
                                car.EscalationName3 = selectedCaseSLA.Employee_Name_L3__c;
                                caseReturnList.add(car);
                            }
                            else
                            {	
                                car = new ECSS_CaseAssignmentReturn();
                                car.caseId = caseRecord.Id;
                                if(selectedCaseSLA.Active_Email__c )
                                    car.EmailTemplate = selectedCaseSLA.Email_Template__c;
                                if(action=='First Escalation')
                                    car.Email = selectedCaseSLA.Escalation_Level_1__c;   
                                else if(action=='Second Escalation')
                                    car.Email =  selectedCaseSLA.Escalation_Level_2__c; 
                                else if(action=='Third Escalation')
                                    car.Email =  selectedCaseSLA.Escalation_Level_3__c;      
                                caseReturnList.add(car);
                            }
                            mtdFound =true;
                        }
                        
                    }
                    else if(site_FunctionalCatMap.containsKey(site_FunctionalCode+'|'+caseRecord.CaseCategory__c) 
                            || site_FunctionalCatMap.containsKey(siteCode+'|'+caseRecord.CaseCategory__c) )
                    {
                        List<ECSS_Case_Assignment_SLA__c> ecaList = site_FunctionalCatMap.get(siteCode+'|'+caseRecord.CaseCategory__c);
                        if(site_FunctionalCatMap.containsKey(site_FunctionalCode+'|'+caseRecord.CaseCategory__c)){
                            ecaList = site_FunctionalCatMap.get(site_FunctionalCode+'|'+caseRecord.CaseCategory__c);
                        }
                        for(ECSS_Case_Assignment_SLA__c eca :ecaList)
                        {
                            if(eca.Sub_Category__c!=null && eca.Sub_Category__c == caseRecord.ECSS_Sub_Category_Text__c)
                            {
                                selectedCaseSLA = eca;
                                break;
                            }
                            else if(eca.Sub_Category__c == null)
                                selectedCaseSLA = eca;
                        }
                        if(selectedCaseSLA!=null)
                        {
                            if(action=='Owner')
                            {
                                if(queueMap.containsKey(selectedCaseSLA.Owner_Queue_Name__c.toLowerCase()))
                                {
                                    caseRecord.OwnerId = queueMap.get(selectedCaseSLA.Owner_Queue_Name__c.toLowerCase());
                                    caseRecord.ECSS_Assigned_by_Project_Metadata__c = true;
                                    queueFound = true;
                                }
                                /* if(userMap.containsKey(selectedCaseSLA.Response_Team__c.toLowerCase()))
{
caseRecord.OwnerId = userMap.get(selectedCaseSLA.Response_Team__c.toLowerCase());
caseRecord.ECSS_Assigned_by_Project_Metadata__c = true;  
}*/
                                if(caseRecord.RecordTypeId == ECSSComplaintsRecordTypeId || (caseRecord.RecordTypeId == ECSSQueriesRecordTypeId && !caseRecord.FCR__c))
                                {
                                    caseRecord.ECSS_LatestEscalationLevel__c = 0;
                                    caseRecord.ECSS_SLA_Level_1__c = selectedCaseSLA.SLA_Level_1__c;
                                    caseRecord.ECSS_SLA_Level_2__c = selectedCaseSLA.SLA_Level_2__c;
                                    caseRecord.ECSS_SLA_Level_3__c = selectedCaseSLA.SLA_Level_3__c;
                                }
                                
                            }
                            else if(action=='GetEmails')
                            {
                                car = new ECSS_CaseAssignmentReturn();
                                car.caseId = caseRecord.Id;
                                car.ResponseTeam =  selectedCaseSLA.Response_Team__c;
                                car.Escalation_Email_1 =selectedCaseSLA.Escalation_Level_1__c;
                                car.Escalation_Email_2 = selectedCaseSLA.Escalation_Level_2__c;
                                car.Escalation_Email_3 =selectedCaseSLA.Escalation_Level_3__c;
                                car.EscalationName =selectedCaseSLA.Escalation_Name__c;
                                car.EscalationName2 =selectedCaseSLA.Employee_Name_L2__c;
                                car.EscalationName3 =  selectedCaseSLA.Employee_Name_L3__c;     
                                caseReturnList.add(car);
                            }
                            else
                            {	
                                car = new ECSS_CaseAssignmentReturn();
                                car.caseId = caseRecord.Id;
                                if(selectedCaseSLA.Active_Email__c )
                                    car.EmailTemplate = selectedCaseSLA.Email_Template__c;
                                if(action=='First Escalation')
                                    car.Email = selectedCaseSLA.Escalation_Level_1__c;
                                else if(action=='Second Escalation')
                                    car.Email =selectedCaseSLA.Escalation_Level_2__c;
                                else if(action=='Third Escalation')
                                    car.Email =  selectedCaseSLA.Escalation_Level_3__c;
							   caseReturnList.add(car);
                            }
                            mtdFound = true;
                        }
                    }
                    
                    if(!mtdFound) //if metadata not found by the combination check by Category
                    {
                        if(catMap.containsKey(caseRecord.CaseCategory__c))
                        {
                            for(ECSS_Case_Assignment_SLA__c eca :catMap.get(caseRecord.CaseCategory__c))
                            { 	
                             if(eca.Sub_Category__c!=null && eca.Sub_Category__c == caseRecord.ECSS_Sub_Category_Text__c)
                             {
                                 selectedCaseSLA = eca;
                                 break;
                             }
                             else if(eca.Sub_Category__c == null)
                                 selectedCaseSLA = eca;
                            }
                            if(selectedCaseSLA!=null)
                            {
                                if(action=='Owner')
                                {	
                                    if(queueMap.containsKey(selectedCaseSLA.Owner_Queue_Name__c.toLowerCase()))
                                    {
                                        caseRecord.OwnerId = queueMap.get(selectedCaseSLA.Owner_Queue_Name__c.toLowerCase());
                                        caseRecord.ECSS_Assigned_by_Project_Metadata__c = true;
                                        queueFound = true;
                                    }
                                    /*if(userMap.containsKey(selectedCaseSLA.Response_Team__c.toLowerCase()))
{

caseRecord.OwnerId = userMap.get(selectedCaseSLA.Response_Team__c.toLowerCase());

caseRecord.ECSS_Assigned_by_Project_Metadata__c = true;
}*/
                                    if(caseRecord.RecordTypeId == ECSSComplaintsRecordTypeId || (caseRecord.RecordTypeId == ECSSQueriesRecordTypeId && !caseRecord.FCR__c))
                                    {
                                        caseRecord.ECSS_LatestEscalationLevel__c = 0;
                                        caseRecord.ECSS_SLA_Level_1__c = selectedCaseSLA.SLA_Level_1__c;
                                        caseRecord.ECSS_SLA_Level_2__c = selectedCaseSLA.SLA_Level_2__c;
                                        caseRecord.ECSS_SLA_Level_3__c = selectedCaseSLA.SLA_Level_3__c;

                                    }
                                }
                                else if(action=='GetEmails')
                                {
                                    car = new ECSS_CaseAssignmentReturn();
                                    car.caseId = caseRecord.Id;
                                    car.ResponseTeam =  selectedCaseSLA.Response_Team__c;
                                    car.Escalation_Email_1 = selectedCaseSLA.Escalation_Level_1__c;
                                	car.Escalation_Email_2 = selectedCaseSLA.Escalation_Level_2__c;
                                	car.Escalation_Email_3 = selectedCaseSLA.Escalation_Level_3__c;
                                	car.EscalationName = selectedCaseSLA.Escalation_Name__c;
                                	car.EscalationName2 = selectedCaseSLA.Employee_Name_L2__c;
                                	car.EscalationName3 =  selectedCaseSLA.Employee_Name_L3__c;
                                    caseReturnList.add(car);
                                }
                                else
                                {
                                    car = new ECSS_CaseAssignmentReturn();
                                    car.caseId = caseRecord.Id;
                                    if(selectedCaseSLA.Active_Email__c )
                                        car.EmailTemplate = selectedCaseSLA.Email_Template__c;
                                    if(action=='First Escalation')
                                        car.Email = selectedCaseSLA.Escalation_Level_1__c;
                                    else if(action=='Second Escalation')
                                        car.Email = selectedCaseSLA.Escalation_Level_2__c;
                                    else if(action=='Third Escalation')
                                        car.Email = selectedCaseSLA.Escalation_Level_3__c;
									  caseReturnList.add(car);
                                    
                                }
                            }
                            
                        }
                        
                    }
                    If(!queueFound && action == 'Owner')
                    {
                        System.debug('in quue not found');
                        Group grp = [SELECT Id from Group where Type='Queue' and DeveloperName='CaseHandling_Queue' LIMIT 1];
                        caseRecord.OwnerId = Grp.Id;
                        caseRecord.ECSS_Assigned_by_Project_Metadata__c = true; 
                    }
                } 
                
            }
        }
        System.debug('caseReturnList '+caseReturnList);
        return caseReturnList;
    }
}