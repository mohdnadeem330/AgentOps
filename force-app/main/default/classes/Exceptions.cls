public with sharing class Exceptions {
    
    public class WebServiceException extends Exception {
        public Integer statusCode {get;set;}
    }

    public class UnitsAlreadyBookedException extends Exception {
        public List<Unit__c> units {get;set;}
        public Set<Id> unitRemoved {get;set;}
    }

    public class UnitsTimerExpiredException extends Exception {
        public List<Unit__c> units {get;set;}
    }

    public class DataNotCompleteException extends Exception{
    	public List<String> messages {get;set;}
    }

    public class PaymentPlanException extends Exception{
    }

    public class BudgetUnAvailableException extends Exception{
    }
    
    public class UpdatingAccountsWithDifferentTypesException extends Exception{}

    public class IncorrectFilterException extends Exception{

    }
	public class AlreadyConvertedException extends Exception{}
    public class VIPBrokerLeadException extends Exception {}
    public class InsufficientAccessException extends Exception {}
    public class MultipleEOIException extends Exception {}
    public class BrokerCityException extends Exception {}
    public class BrokerSuspensionException extends Exception {}
    
    public class DocumentVerificationException extends Exception {
        public Integer statusCode {get;set;}  public String message {get;set;}
    }
    
}