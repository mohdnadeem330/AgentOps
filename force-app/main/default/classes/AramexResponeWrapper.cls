public class AramexResponeWrapper {
    // public List<TResponse> Transaction;	
    public Boolean HasErrors;
    public List<SResponse> Shipments;
    public List<TRResponse> TrackingResults;

    // public class TResponse {
    //     public String Reference1;
    //     public String Reference2;
    //     public String Reference3;
    //     public String Reference4;
    //     public String Reference5;
    // }

    public class SResponse {
        public String Id;
        public String Reference1;
        public String Reference2;
        public String Reference3;
        public String ForeignHAWB;
        public Boolean HasErrors;
        public SLResponse ShipmentLabel;
        public SDResponse ShipmentDetails;
    }

    public class SLResponse {
        public String LabelURL;
    }

    public class SDResponse {
        public String Origin;
        public String Destination;
        public CWResponse ChargeableWeight;
        public String DescriptionOfGoods;
        public String GoodsOriginCountry;
        public Double NumberOfPieces;
        public String ProductGroup;
        public String ProductType;
        public String PaymentType;
        public String PaymentOptions;
        public Double CustomsValueAmount;
        public Double CashOnDeliveryAmount;
        public Double InsuranceAmount;
        public Double CashAdditionalAmount;
        public Double CollectAmount;
        public String Services;
        public String OriginCity;
        public String DestinationCity;
    }

    public class CWResponse {
        public String Unit;
        public Double Value;
    }

    public class TRResponse {
        public String Key;
        public List<VResponse> Value;
    }

    public class VResponse {
        public String WaybillNumber;
        public String UpdateCode;
        public String UpdateDescription;
        public String UpdateDateTime;
        public String UpdateLocation;
        public String Comments;
        public String ProblemCode;
        public String GrossWeight;
        public String ChargeableWeight;
        public String WeightUnit;
    }
}