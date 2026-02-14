@RestResource(urlMapping='/retail/rdd/lease-details/*')
global with sharing class RETL_ProposalAPI {

    @HttpGet
    global static void getProposal() {
        RestResponse res = RestContext.response;
        RestRequest req = RestContext.request;

        try {
            // Read proposalId from query params
            String proposalId = req.params.get('proposalId');

            // Input validation
            if (String.isBlank(proposalId)) {
                returnError(400, 'Please provide a valid proposalId.');
                return;
            }
System.debug('called');
            // Call service layer
            String jsonResponse = RETL_ProposalAPIService.buildProposalJSON(proposalId);

            // Success response
            res.statusCode = 200;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(jsonResponse);
        }
        catch (Exception e) {
            returnError(500, 'Unexpected Error: ' + e.getMessage());
        }
    }


    /** 
     * Helper method to send JSON error responses
     */
    private static void returnError(Integer status, String message) {
        RestResponse res = RestContext.response;
        res.statusCode = status;
        res.addHeader('Content-Type', 'application/json');

        Map<String, Object> errorBody = new Map<String, Object>{
            'status' => 'Error',
            'message' => message,
            'data'    => null
        };

        res.responseBody = Blob.valueOf(JSON.serializePretty(errorBody));
    }
}