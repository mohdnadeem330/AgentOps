/**********************************************************************************************************************
* Name               : AssignRequestEmailController                                                        
* Description        : 
* Usage              : 
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           @pwc.com     06/06/2022      Initial Draft       
******************************************************************************************************************/
global with sharing class AssignRequestEmailController {
    global List<String> selectedUnitsIds{get;set;}

    //Constructor
    public AssignRequestEmailController() {}
    // get logged in user's manager
    global String managerName{
        get{        
            String userManagerName;
            USER userData = [SELECT Id,ManagerId FROM USER WHERE Id=:UserInfo.getUserId()];
            USER managerData = [SELECT Id,name FROM USER WHERE Id=:userData.ManagerId];
            userManagerName = managerData.name;
            return  userManagerName;
        }
        set;
    }

    // get Unit list
    global List<Unit__c> selectedUnitsList{
        get{        
            List<Unit__c>untsToDisplay = new List<Unit__c>();
            List<Unit__c> unitList = [SELECT Id,Name,Project__c,SellingPrice__c,AllocationGroupUser__c FROM Unit__c WHERE Id IN: selectedUnitsIds];
            for(Unit__c p:unitList){
                untsToDisplay.add(p);
            }            
            return  untsToDisplay;
        }
        set;
    }
}