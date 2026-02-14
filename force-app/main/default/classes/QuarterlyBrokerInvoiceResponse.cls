/**********************************************************************************************************************
* Name               : QuarterlyBrokerInvoiceResponse                                                       
* Description        : Controller to parse the response for ERP API for Quarter Commission
* Usage              : ERP Mulesoft Integration                                               
* Created By         : Sanket Kumar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           sajkumar@aldar.com      10 April 2023   Initial Draft       
******************************************************************************************************************/
public class QuarterlyBrokerInvoiceResponse {
    public String applicationName;
	public Boolean success;
	public String statusCode;
	public String correlationId;
	public Results results;

	public class Results {
		public List<BonusInvRes> BonusInvRes;
	}

	public class BonusInvRes {
		public String SFID;
		public String ErpId;
		public String status;
		public String errorMsg;
		public String invoiceNum;
	}
    
    public static QuarterlyBrokerInvoiceResponse parse(String json){
		return (QuarterlyBrokerInvoiceResponse) System.JSON.deserialize(json, QuarterlyBrokerInvoiceResponse.class);
	}

}