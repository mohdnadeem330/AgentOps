/**
* @File Name : PremPark_OrderIntegrationWrappers.cls
* @Description :
* @Author : Harsh@Aldar
* @Last Modified By :
* @Last Modified On : October 15, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 15, 2024 | Harsh@Aldar | Initial Version
**/

public class PremPark_OrderIntegrationWrappers {
	
	public list<parkingOrder> parkingOrder{get;set;}

	public class parkingOrderLines{
		public String productName{get;set;}
		public String productId{get;set;}
		public String quantity{get;set;}
		public String orderId{get;set;}
		public String quotedPrice{get;set;}
		public String totalPrice{get;set;}
		public String inventoryFlag{get;set;}
		public String unitPrice{get;set;}
	}

	public class parkingOrder{
		public String orderAmount{get;set;}
		public String orderID{get;set;}
		public String orderStatus{get;set;}
		public String sfSalesOrderId{get;set;}
		public list<parkingOrderLines> parkingOrderLines{get;set;}
		public String sfCustomerSfId{get;set;}
		public String erpCustomerId{get;set;}
	}

	public class ERPResponse {
		public String applicationName { get; set; }
		public Boolean success { get; set; }
		public String statusCode { get; set; }
		public String correlationId { get; set; }
		public List<Result> results { get; set; }
	}

	public class Result {
        public String sfRequestId { get; set; }
        public String sfOrderId { get; set; }
        public String status { get; set; }
        public String errorMsg { get; set; }
        public String erpID { get; set; }
    }
}