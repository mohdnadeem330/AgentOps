/******************************************************************************************
 *  Author      : Keerthan
 *  Company     : HexaBPM
 *  Description : Apex Class which will help to configure the conditions for the SR Template Docs
 *  Date        : 30-Nov-2016
*******************************************************************************************/
public with sharing class FLSCheckUtil {
    /*
        Method Name :   CheckQueryFieldAccess
        Description :   Pass the Set of Fields with Comma Seperated as first Input Param and the Object Name as Second Input Param to check FLS.
    */
    public static Boolean CheckQueryFieldAccess(String queryFields, String obj) {
        Map<String, String> inputMap = new Map<String, String>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        //String objName =  (obj.toLowerCase().indexOf('HexaBPM__') == -1) ? 'HexaBPM__' + obj : obj;
        String ObjName;
        
        if(obj.toLowerCase().indexOf('__c') > -1 && obj.toLowerCase().indexOf('hexabpm__') == -1)
            ObjName =  'HexaBPM__' + obj;
        else
             objName = obj;
        Schema.SObjectType sobjType = gd.get(objName);
        Schema.DescribeSObjectResult describeResult = sobjType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
        Boolean isAccessible = true;

        for(String s : queryFields.split(',')) {
            inputMap.put(s.toLowerCase(), s.toLowerCase());
        }
        for(Schema.SObjectField f : fieldsmap.values()) {
            Schema.DescribeFieldResult fd = f.getDescribe();
            if(!fd.isAccessible() && inputMap.containsKey(string.valueOf(f).toLowercase())) {
                isAccessible = false;
            }
        }
        return isAccessible;
    }
    
    /*
        Method Name :   fldFLS
        Description :   Checks the Folder & Email Template Access.
    */
    public static Boolean fldFLS(String fldStr, String obj) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = gd.get(obj);
        Schema.DescribeSObjectResult describeResult = sobjType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
        Boolean isAccessible = false;
        for (Schema.SObjectField f : fieldsmap.values()) {

            Schema.DescribeFieldResult fd = f.getDescribe();
            if (fd.isAccessible() && String.valueOf(f).toLowercase().equals(fldStr)) {
                isAccessible  = true;
            }
        }

        return isAccessible;
    }

    /**************************************************************************************************
      Method:         isUpdateable
      Description:    This method checks if the fields have edit and create access
    **************************************************************************************************/
    public static Boolean isUpdateable(String queryFields,String obj){
      Map<String, String> inputMap = new Map<String, String>();
      Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
      String objName = obj; //(obj.toLowerCase().indexOf('__c') > -1) ? 'HexaBPM__' + obj : obj;
      system.debug('Object Name==>'+ObjName);
      Schema.SObjectType sobjType = gd.get(objName);
      Schema.DescribeSObjectResult describeResult = sobjType.getDescribe();
      Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
      Boolean isUpdateableField = true;

      for (String s : queryFields.split(',')) {
          inputMap.put(s.toLowerCase(), s.toLowerCase());
      }
      for (Schema.SObjectField f : fieldsmap.values()) {
          Schema.DescribeFieldResult fd = f.getDescribe();
          if ((!fd.isUpdateable() || !fd.isCreateable())  && inputMap.containsKey(string.valueOf(f).toLowercase())) {
              isUpdateableField = false;
          }
      }
      return true ;
  }

}