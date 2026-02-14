global with sharing class LPCFinanceEmailController{

    global String srId{get;set;}
    
    global  LPCFinanceEmailController(){
    }
    
    global List<HexaBPM__Step__c> reqList{
        get{        

            List<HexaBPM__Step__c> stepsToDisplay = [SELECT Id, HexaBPM__Start_Date__c, HexaBPM__Summary__c, Owner.Name, HexaBPM__Step_Status__c, HexaBPM__Step_Notes__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c =:srId];
            return  stepsToDisplay;
        }
        set;
    }

    global HexaBPM__Service_Request__c srDetails{
        get{        

            HexaBPM__Service_Request__c srRecord = [SELECT Id, SalesOrder__c, SalesOrder__r.UnitNumber__c, TotalLPCCollected__c, TotalLPCDue__c, TotalLPCAmount__c, ServiceRequestComments__c, owner.name, WaivedAmount__c, WaivedPercentage__c, ChargeCollected__c FROM HexaBPM__Service_Request__c WHERE Id =:srId];
            return  srRecord;
        }
        set;
    }

    global Decimal totalOutstanding{
        get{        

            List<InstallmentLines__c> installmentsList = [SELECT Id, SalesOrder__c, OutstandingAmount__c, InstallmentDate__c FROM InstallmentLines__c WHERE SalesOrder__c =:srDetails.SalesOrder__c AND InstallmentDate__c <= TODAY];
            
            Decimal outstanding = 0;

            for (InstallmentLines__c rec : installmentsList) {
                outstanding = outstanding + rec.OutstandingAmount__c;
            }

            return  outstanding;
        }
        set;
    }
    
    
    global String NewLine {
        get { return '\r\n'; }
        set;
    }
}