/**********************************************************************************************************************
* Name               : SendGridWithoutSharingUtil                                                        
* Description        : Without Sharing DML Service Class
* Created By         : Harsh@Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     15/09/2023      Initial Draft       
******************************************************************************************************************/
public without sharing class SendGridWithoutSharingUtil {
    public static void doDML_List(List<sObject> recordList, String dmlType){
        if(recordList.size() > 0){
            if(dmlType.toLowerCase() == 'update'){
                update recordList;
            }
        }
    }
    public static void doDML_SingleObject(sObject thisRecord, String dmlType){
        if(thisRecord != null){
            if(dmlType.toLowerCase() == 'insert'){
                insert thisRecord;
            }else if(dmlType.toLowerCase() == 'upsert'){
                upsert thisRecord;
            }
            else if(dmlType.toLowerCase() == 'update'){
                update thisRecord;
            }
        }
    }
}