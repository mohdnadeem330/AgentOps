/******************************************************************************************
 *  Company     : Pwc
 *  Date        : 20/02/2020
 *  Description : Utility class
 *******************************************************************************************/
public without sharing class QueryUtilityClass {
    public static string getMessageFromDMLException(DMLException e) {
        string DMLError = '';
        Integer numErrors = e.getNumDml();
    
        for (Integer i = 0; i < numErrors; i++) {
          String errorMsg = (e.getDmlMessage(i) != null ? e.getDmlMessage(i) : '');
          DMLError = DMLError + errorMsg + '\n';
        }
    
        if (DMLError == null) {
          DMLError = e.getMessage() + '';
        }
        if (String.IsNotBlank(DMLError) && DMLError.containsIgnoreCase('data value too large'))
          DMLError = 'The character limit has exceeded.';
        else if(String.IsNotBlank(DMLError) && DMLError.containsIgnoreCase('value outside of valid range'))
          DMLError = DMLError.SubStringBefore(':') + ': The value entered is outside of valid range.';
    
        return DMLError;
      } 
  }