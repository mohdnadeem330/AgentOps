public class CapillaryAddPointsResponseModel {
    @AuraEnabled public Integer entityId;    //360744868
    @AuraEnabled public cls_result result;
    @AuraEnabled public cls_errors[] errors;
    @AuraEnabled public cls_warnings[] warnings;
    public class cls_result {
        @AuraEnabled public String identifierType;   //id
        @AuraEnabled public String identifierValue;  //98662653
        @AuraEnabled public String source;   //INSTORE
        @AuraEnabled public cls_extendedFields extendedFields;
        @AuraEnabled public String deliveryStatus;   //SHIPPED
        @AuraEnabled public String type; //REGULAR
        @AuraEnabled public Double billAmount;  //4808
        @AuraEnabled public String grossAmount;
        @AuraEnabled public String billNumber;   //test244e79c384598f5f9a265581d652a010a14717465
        //@AuraEnabled public String currency; //INR
        @AuraEnabled public Double discount;    //0
        @AuraEnabled public cls_lineItemsV2[] lineItemsV2;
        @AuraEnabled public cls_customFields customFields;
        @AuraEnabled public String notInterestedReason;  //
        @AuraEnabled public cls_sideEffects[] sideEffects;
        @AuraEnabled public cls_paymentModes[] paymentModes;
        @AuraEnabled public String billingDate;  //2021-07-05T14:10:00Z
        @AuraEnabled public boolean useDefaultFleetGroup;
    }
    public class cls_extendedFields {
    }
    public class cls_lineItemsV2 {
        @AuraEnabled public Double amount;  //8
        @AuraEnabled public String itemCode; //CGST
        @AuraEnabled public Double qty; //1
        @AuraEnabled public boolean returnable;
        @AuraEnabled public Integer returnableDays;  //-1
        @AuraEnabled public cls_comboDetails[] comboDetails;
        @AuraEnabled public cls_addOnDetails[] addOnDetails;
        @AuraEnabled public cls_splitDetails[] splitDetails;
        @AuraEnabled public cls_extendedFields extendedFields;
    }
    public class cls_comboDetails {
    }
    public class cls_addOnDetails {
    }
    public class cls_splitDetails {
    }
    public class cls_customFields {
        @AuraEnabled public String booking_ota;  //Website
        @AuraEnabled public String conf_no;  //508705535
        @AuraEnabled public String fare_class;   //X
        @AuraEnabled public String flight_destination;   //CCU
        @AuraEnabled public String flight_number;    //550
        @AuraEnabled public String flight_source;    //DEL
        @AuraEnabled public String seat_number;  //28B
        @AuraEnabled public String trip_type;    //1
    }
    public class cls_sideEffects {
        @AuraEnabled public String entityType;   //USER
        @AuraEnabled public Double rawAwardedPoints; //480.8
        @AuraEnabled public Integer awardedPoints;   //480
        @AuraEnabled public String type; //points
    }
    public class cls_paymentModes {
        @AuraEnabled public String mode; //Card Payment
        @AuraEnabled public String value;   //4808
        @AuraEnabled public String notes;    //CardPay
        @AuraEnabled public cls_attributes attributes;
    }
    public class cls_attributes {
        @AuraEnabled public String card_type;    //Debit Card
    }
    public class cls_errors {
        @AuraEnabled public boolean status;
        @AuraEnabled public Integer code;    //8084
        @AuraEnabled public String message;  //Customer details not sent
    }
    public class cls_warnings {
        @AuraEnabled public boolean status;
        @AuraEnabled public Integer code;    //91016
        @AuraEnabled public String message;  //Extended field name gender is invalid.
    }
}