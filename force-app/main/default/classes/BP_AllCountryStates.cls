@RestResource(urlMapping='/countryStatePicklist')
global with sharing class BP_AllCountryStates extends BP_BaseRestResource {

    @HttpGet
    global static void doGet() {
        BP_AllCountryStates instance = new BP_AllCountryStates();
        Map<String, String> params = RestContext.request.params;
        String requestBody = ''; 

        ApiResponse apiResponse = instance.processRequest(params, requestBody);

        RestContext.response.statusCode = apiResponse.statusCode;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(apiResponse));
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            System.debug('params123'+params);
             System.debug('requestBody123'+requestBody);
            CountryStateResponse countryStateResponse = new CountryStateResponse();
            System.debug('countryStateResponse'+countryStateResponse);
            String countryParam = params.containsKey('country') ? params.get('country') : null;
               System.debug('countryParam'+countryParam);
            getCountryStatePicklistValues(countryStateResponse, countryParam);

            return new ApiResponse(true, 200, 'Success', countryStateResponse);
        } catch (Exception ex) {
            return handleException(ex, 500);
        }
    }

    private static void getCountryStatePicklistValues(CountryStateResponse response, String countryFilter) {
        Schema.DescribeFieldResult countryFieldResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> countryPle = countryFieldResult.getPicklistValues();

        List<String> countryEntries = new List<String>();
        for (Schema.PicklistEntry entry : countryPle) {
            countryEntries.add(entry.getLabel());
        }

        Map<String, List<String>> dependentStates = getDependentPicklistValues(User.Statecode);

        // Add empty list for countries with no dependent states
        for (String country : countryEntries) {
            if (!dependentStates.containsKey(country)) {
                dependentStates.put(country, new List<String>());
            }
        }

        if (String.isNotBlank(countryFilter)) {
            Map<String, List<String>> filtered = new Map<String, List<String>>();
            if (dependentStates.containsKey(countryFilter)) {
                filtered.put(countryFilter, dependentStates.get(countryFilter));
            }
            response.countriesAndStates = filtered;
        } else {
            response.countriesAndStates = dependentStates;
        }
    }

    public static Map<String, List<String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
    Map<String, List<String>> dependentPicklistValues = new Map<String, List<String>>();
    
    try {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        
        if (controlToken == null) {
            return dependentPicklistValues;
        }

        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if (control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }

        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && 
                String.isNotEmpty(String.valueOf(((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                
                List<String> base64chars = String.valueOf(
                    ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')
                ).split('');
                
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue = (controlEntries == null 
                        ? (Object)(index == 1) 
                        : (Object)(controlEntries[index].isActive() ? controlEntries[index].getLabel() : null));
                    
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) break;
                    
                    Integer bitShift = 5 - Math.mod(index, 6);
                    
                    if (controlValue == null || 
                        (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0) {
                        continue;
                    }
                    
                    String controlLabel = (String)controlValue;
                    if (!dependentPicklistValues.containsKey(controlLabel)) {
                        dependentPicklistValues.put(controlLabel, new List<String>());
                    }
                    dependentPicklistValues.get(controlLabel).add(entry.getLabel());
                }
            }
        }
    } catch (Exception ex) {
        LoggerService.save(LoggerService.addApexLog(
            ex,'Broker2.0 API','BP_AllCountryStates',  'getDependentPicklistValues'
        ));
    }

    return dependentPicklistValues;
}


    public class CountryStateResponse {
        public Map<String, List<String>> countriesAndStates { get; set; }
    }
}