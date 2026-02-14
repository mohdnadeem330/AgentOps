public with sharing class ScheduleADMCreateAppCall implements Schedulable{
        private Map<String,String> headerConfiguration;
        private String JSONBody;
        private String muleConfig;
        private String extraParam;
        private Id srId;
    
        public ScheduleADMCreateAppCall(Map<String,String> headerConfiguration, String JSONBody, String muleConfig, String extraParam, Id srId) {
            this.headerConfiguration = headerConfiguration;
            this.JSONBody = JSONBody;
            this.muleConfig = muleConfig;
            this.extraParam = extraParam;
            this.srId = srId;
        }
    
        public void execute(SchedulableContext sc) {
            // Call the method again after two minutes
            ADMRegistrationUtility.ADMCalloutHelperForCreateApplication(headerConfiguration, JSONBody, muleConfig, extraParam, srId);
        }
    }