/*
*Description : Class for logging exception, callout service logs, mobile logs
*/
public without sharing class LoggerService {
    
    public static List<Logger__c> loggers {get; private set;}
    
    private static final String LOG_TYPE_APEX_EXCEPTION = 'Apex Exception';
    private static final String LOG_TYPE_MOBILE_EXCEPTION = 'Mobile Log';
    private static final String LOG_TYPE_CALLOUT = 'Callout Log';
    private static final String LOG_TYPE_SERVICE_EXCEPTION = 'Service Exception';  
    
    private static void initializeList() {
        
        if (loggers == null)
            loggers = new List<Logger__c>();
    }
    
    public static Logger__c logSuccessResponse(string processName, string className, string methodName, string request, string response,Id recordId){
        Logger__c newLog = new Logger__c();
        newLog.Message__c = request;
        newLog.ResponseMessage__c = response;
        newLog.ExceptionTypeName__c = 'Success Log';
        newLog.ExecutingProcessName__c = processName;
        newLog.ClassName__c = className;
        newLog.MethodName__c = methodName;
        newLog.LogType__c = LOG_TYPE_CALLOUT;
        newLog.ExceptionLogId__c = system.now().format()+'-'+className+'-'+methodName;
        if(recordId !=null){
            if(recordId.getSObjectType() == Lead.SObjectType) {
                newLog.Lead__c = recordId;
            } else if (recordId.getSObjectType() == Account.SObjectType) {
                newLog.Account__c = recordId;
            } else if (recordId.getSObjectType() == BrokerRequest__c.SObjectType) {
                newLog.BrokerRequest__c = recordId;
            } else if (recordId.getSObjectType() == JointOwner__c.SObjectType) {
                newLog.JointOwner__c = recordId;
            } else if (recordId.getSObjectType() == ReceiptAcknowledgement__c.SObjectType) {
                newLog.ReceiptAcknowledgement__c = recordId;
            } else if (recordId.getSObjectType() == SalesOrder__c.SObjectType) {
                newLog.SalesOrder__c = recordId;
            } else if (recordId.getSObjectType() == ShipmentRequest__c.SObjectType) {
                newLog.ShipmentRequest__c = recordId;
            } else if (recordId.getSObjectType() == HexaBPM__Service_Request__c.SObjectType) {
                newLog.ServiceRequest__c = recordId;
            }else if (recordId.getSObjectType() == DDTransaction__c.SObjectType) {
                newLog.DDTransaction__c = recordId;
            }
            //[26/10 Harsh@Aldar] Added for document
            else if (recordId.getSObjectType() == Document__c.SObjectType) {
                newLog.Document__c = recordId;
            }
            //18/06/2025 Harsh@Aldar - Added for Order__c
            else if (recordId.getSObjectType() == Order.SObjectType) {
                newLog.Order__c = recordId;
            }
        }
        
        return newLog;
    }
    
    public static void addLog(string processName, string message){
        Logger__c newLog = new Logger__c();
        newLog.Message__c = message;
        newLog.ExecutingProcessName__c = processName;
        newLog.ExceptionLogId__c = 'CustomerCreate'+string.valueof(system.now());
    }
    
    //------Initialise Exception Logger
    public static Logger__c addApexLog(Exception exc, string processName, string className, string methodName){      
        initializeList();
        Logger__c newLog = createApexLog(exc, processName, className, methodName);
        loggers.add(newLog);
        return newLog;
    }
    
    //------Initialise Exception Logger
    public static Logger__c addApexServiceCalls(string processName, string className, string methodName, string request, string response,Id recordId){      
     
        Logger__c newLog = new Logger__c();
        newLog.Message__c = request;
        newLog.ResponseMessage__c = response;
        newLog.ExceptionTypeName__c = 'ServiceCall';
        newLog.ExecutingProcessName__c = processName;
        newLog.ClassName__c = className;
        newLog.MethodName__c = methodName;
        newLog.LogType__c = LOG_TYPE_CALLOUT;
        newLog.ExceptionLogId__c = system.now().format()+'-'+className+'-'+methodName;
        if(recordId !=null){
            if(recordId.getSObjectType() == Lead.SObjectType) {
                newLog.Lead__c = recordId;
            } else if (recordId.getSObjectType() == Account.SObjectType) {
                newLog.Account__c = recordId;
            } else if (recordId.getSObjectType() == BrokerRequest__c.SObjectType) {
                newLog.BrokerRequest__c = recordId;
            } else if (recordId.getSObjectType() == JointOwner__c.SObjectType) {
                newLog.JointOwner__c = recordId;
            } else if (recordId.getSObjectType() == ReceiptAcknowledgement__c.SObjectType) {
                newLog.ReceiptAcknowledgement__c = recordId;
            } else if (recordId.getSObjectType() == SalesOrder__c.SObjectType) {
                newLog.SalesOrder__c = recordId;
            } else if (recordId.getSObjectType() == ShipmentRequest__c.SObjectType) {
                newLog.ShipmentRequest__c = recordId;
            } else if (recordId.getSObjectType() == HexaBPM__Service_Request__c.SObjectType) {
                newLog.ServiceRequest__c = recordId;
            }else if (recordId.getSObjectType() == DDTransaction__c.SObjectType) {
                newLog.DDTransaction__c = recordId;
            }/* else if (recordId.getSObjectType() == SalesOrderOtherCharges__c.SObjectType) { //SS_CHANGES_OTHER_CHARGE
                newLog.Sales_Order_Other_Charges__c = recordId;//SS_CHANGES_OTHER_CHARGE
            }*/

            //[26/10 Harsh@Aldar] Added for document
            else if (recordId.getSObjectType() == Document__c.SObjectType) {
                newLog.Document__c = recordId;
            }
            //18/06/2025 Harsh@Aldar - Added for Order__c
            else if (recordId.getSObjectType() == Order.SObjectType) {
                newLog.Order__c = recordId;
            }
        }
             
        return newLog;
    }

    public static Logger__c addApexServiceCallsLog(Exception exc, string className, string methodName, string processName, string request, string response){      
        Logger__c newLog = new Logger__c();
        newLog.Message__c = request;
        newLog.ResponseMessage__c = response;
        newLog.StackTrace__c = exc.getStackTraceString()+' ***---*** Exception Message: '+exc.getMessage();
        newLog.ExceptionMessage__c = exc.getMessage();
        newLog.ExceptionTypeName__c = 'DeserializationException';
        newLog.ExecutingProcessName__c = processName;
        newLog.ClassName__c = className;
        newLog.MethodName__c = methodName;
        newLog.LogType__c = LOG_TYPE_SERVICE_EXCEPTION;
        newLog.ExceptionLogId__c = system.now().format()+'-'+className+'-'+methodName+'- Line#-'+exc.getLineNumber();
        return newLog;
    }
    
    //------Initialise Exception Logger
    public static Logger__c createApexLog(Exception exc, string processName, string className, string methodName) {       
        Logger__c newLog = new Logger__c();
        Integer lineNumber = exc.getLineNumber();
        newLog.LineNumber__c = lineNumber;
        newLog.Message__c = exc.getMessage(); 
        newLog.ExceptionMessage__c = exc.getMessage();
        newLog.StackTrace__c = exc.getStackTraceString();
        newLog.ExceptionTypeName__c = exc.getTypeName();
        newLog.ExecutingProcessName__c = processName;
        newLog.ClassName__c = className;
        newLog.MethodName__c = methodName;
        newLog.LogType__c = LOG_TYPE_APEX_EXCEPTION;
        newLog.ExceptionLogId__c = system.today().format()+'-'+className+'-'+methodName+'- Line#-'+lineNumber;
        return newLog;
    }

    //------Initialise Database Error Logger
    public static Logger__c createApexLog(Database.Error err, string processName, string className, string methodName){       
        Logger__c newLog = new Logger__c();
        newLog.Message__c = err.getMessage() ;
        newLog.StackTrace__c = 'StatusCode-'+String.valueOf(err.getStatusCode())+'-Fields-'+String.valueOf(err.getFields());
        newLog.ExecutingProcessName__c = processName ;
        newLog.ClassName__c = className ;
        newLog.MethodName__c = methodName ;
        newLog.LogType__c = LOG_TYPE_APEX_EXCEPTION;
        String exceptionLogId = system.today().format()+'-'+className+'-'+methodName+'- StatusCode-'+String.valueOf(err.getStatusCode());
        if(exceptionLogId.length() > 255 )
              exceptionLogId = exceptionLogId.substring(0,254);
        newLog.ExceptionLogId__c = exceptionLogId ;        
        return newLog;  
    }

    //------Initialise Database Error Logger
    public static Logger__c addApexLog(Database.Error err, string processName, string className, string methodName){
        
        initializeList();
        Logger__c newLog = createApexLog(err, processName, className, methodName);       
        loggers.add(newLog);
        return newLog;  
    }
    
    
    //------Upsert Mobile/Exception Logs
    public static void save(){
        if(loggers.size()>0 && !loggers.isEmpty()){
            upsert loggers ; 
        }               
    }
    
    //------Upsert Mobile/Exception Logs
    @future
    public static void aynchronousSave( string jsonSring){
        list<Logger__c> lstLogs = (list<Logger__c>)json.deserialize(jsonSring,list<Logger__c>.Class);
        
        if(lstLogs != null && !lstLogs.isEmpty()){
            insert lstLogs;
        }
    }
    
    //------Upsert Mobile/Exception Log
    public static void save(Logger__c loggerRecord){
        if(loggerRecord !=null){
           upsert loggerRecord ;        
        }
    }

    //Returning the loggerRecord to copy the logger id in the base record - SAL-597 SARAN
    public static Logger__c saveAndReturnLogger(Logger__c loggerRecord){
        if(loggerRecord !=null){
            upsert loggerRecord ;  
            return loggerRecord;
        }
        return null;
    }
    
    //------Initialise Mobile Logger
    public static Logger__c addMobileLog(RestRequest restRequest, Exception exc, String responseMessage, Integer statusCode) {
        
        initializeList();
        
        Logger__c newLog = new Logger__c();
        newLog = updateMobileLog(newLog, restRequest, exc, responseMessage, statusCode);
        loggers.add(newLog);
        return newLog;
    }

    public static Logger__c updateMobileLog(Logger__c logger, RestRequest restRequest, Exception exc, String responseMessage, Integer statusCode) {
        logger.LogType__c = LOG_TYPE_MOBILE_EXCEPTION;
            
        Map<String, String> requestHeaders = restRequest.headers;        
        Map<String, String> headerToLogField = new Map<String, String>{
            'App-Version' => 'AppVersion__c',
            'Device-OS' => 'DeviceOS__c',
            'Device-OS-Version' => 'DeviceOSVersion__c',
            'Device-Model' => 'DeviceModel__c',
            'Build-Number' => 'BuildNumber__c'
        };
            
        for (String headerKey : headerToLogField.keySet()) {       
            if (requestHeaders.containsKey(headerKey)) {          
                String headerValue =  requestHeaders.get(headerKey);
                String logField = headerToLogField.get(headerKey);             
                logger.put(logField, headerValue);
            }
        }
        
        if (exc != null) {          
            logger.LineNumber__c = exc.getLineNumber();
            logger.ExceptionTypeName__c = exc.getTypeName(); 
            logger.StackTrace__c = exc.getStackTraceString();
            logger.Message__c = exc.getMessage();
        }  
        system.debug('inside logger');
        logger.ResourcePath__c = restRequest.resourcePath;
        logger.StatusCode__c = statusCode;
        logger.ResponseMessage__c = responseMessage;
        logger.ExceptionLogId__c = (system.today().format() + '-' + logger.ResourcePath__c);

        return logger;      
    }
}