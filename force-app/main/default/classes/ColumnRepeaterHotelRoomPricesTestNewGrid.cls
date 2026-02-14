/**
 * @Version: 1.0
 * @Author: Frederik
 * @Copyright: 2021 Upeo Consulting
 * @Uses:
 *
 * -----------------------------------------------------------------------------------------------
 * Description: 
 *
 *
 * Created: 22/09/2022
 * Last Updated: 22/09/2022
 *
 * Unit tests:
 *
 * Change log:
 * -----------------------------------------------------------------------------------------------
*/
@IsTest
global class ColumnRepeaterHotelRoomPricesTestNewGrid {
    @TestSetup 
    static void setup() {
        thn__ByPass__c  byPassValues = thn__ByPass__c.getOrgDefaults();
        byPassValues.thn__QuoteHotelRoomDisabled__c  = true;
        insert byPassValues;
        thn__Hotel__c hotel = new thn__Hotel__c ();
        hotel.name = 'Al Dhafra Resort';
        insert hotel;
        thn__Space_Area__c roomType = new thn__Space_Area__c();
        roomType.name = 'test';
        roomType.thn__Is_Inactive__c = false; 
        roomType.thn__Hotel__c = hotel.id;
         
        insert roomType;
        thn__MYCE_Quote__c myceQuote = new thn__MYCE_Quote__c();
        myceQuote.name = 'test';
        myceQuote.thn__Hotel__c = hotel.id;
        //myceQuote.thn__Type__c = 'Residential';
        //myceQuote.thn__Subtype__c = 'Non-Commissionable';
        myceQuote.thn__Arrival_Date__c = Date.today() + 10;
        myceQuote.thn__Departure_Date__c = Date.today() + 20;
        myceQuote.thn__Pax__c  = 2;
        insert myceQuote;
        system.debug('myceQuote'+myceQuote);
        thn__Rate__c  rate = new thn__Rate__c ();
        rate.thn__IsActive__c = true;
        rate.thn__Hotel__c  = hotel.id;
        insert rate;
        thn__Product__c product = new thn__Product__c();
        product.name = 'Product test';
        product.thn__MYCE_Product_Type__c = 'Hotel Room';
        product.thn__Type__c ='Hotel Room';
        product.thn__Is_Active__c = true;
        product.thn__Hotel__c =  hotel.id;
        product.thn__Price_Net_Value__c = 0;
        insert product;
        list<thn__Quote_Hotel_Room__c> quoteHotelRoomList = new List<thn__Quote_Hotel_Room__c>();
        thn__Quote_Hotel_Room__c quoteHotelRoom = new thn__Quote_Hotel_Room__c();
        quoteHotelRoom.Name = 'Hotel room';
        quoteHotelRoom.thn__Property__c = hotel.id; 
        quoteHotelRoom.thn__Space_Area__c  = roomType.id; 
        quoteHotelRoom.thn__Type_of_Occupancy__c = 'Single';
        quoteHotelRoom.thn__MYCE_Quote__c = myceQuote.id;
        quoteHotelRoom.thn__Product__c = product.id;
        //quoteHotelRoom.thn__Rate_Plan__c = rate.id;
        quoteHotelRoom.thn__Arrival_Date_Time__c = System.now() + 10;
        quoteHotelRoom.thn__Arrival_Date__c  =  Date.today() + 10;
        quoteHotelRoom.thn__Departure_Date_Time__c  = System.now() + 20;
        quoteHotelRoom.thn__Departure_Date__c = Date.today() + 20 ;
        quoteHotelRoom.thn__Unit_Price__c = 5; 
        quoteHotelRoom.thn__Number_of_Adults__c = 5;
        quoteHotelRoomList.add(quoteHotelRoom);
        thn__Quote_Hotel_Room__c quoteHotelRoom1 = new thn__Quote_Hotel_Room__c();
        quoteHotelRoom1.Name = 'Hotel room';
        quoteHotelRoom1.thn__Property__c = hotel.id;    
        quoteHotelRoom1.thn__Space_Area__c  = roomType.id; 
        quoteHotelRoom1.thn__Type_of_Occupancy__c = 'Single';
        quoteHotelRoom1.thn__MYCE_Quote__c = myceQuote.id;
        quoteHotelRoom1.thn__Product__c = product.id;
        //quoteHotelRoom.thn__Rate_Plan__c = rate.id;
        quoteHotelRoom1.thn__Arrival_Date_Time__c = System.now() + 10;
        quoteHotelRoom1.thn__Arrival_Date__c  =  Date.today() + 10;
        quoteHotelRoom1.thn__Departure_Date_Time__c  = System.now() + 20;
        quoteHotelRoom1.thn__Departure_Date__c = Date.today() + 20 ;
        quoteHotelRoom1.thn__Unit_Price__c = 5; 
        quoteHotelRoom1.thn__Number_of_Adults__c = 5;
        quoteHotelRoomList.add(quoteHotelRoom1);
        insert quoteHotelRoomList;
        List<thn__Quote_Hotel_Room_Price__c> quoteHotelRoomPriceList = new List<thn__Quote_Hotel_Room_Price__c>();
        thn__Quote_Hotel_Room_Price__c quoteHotelRoomPrice = new thn__Quote_Hotel_Room_Price__c();
        quoteHotelRoomPrice.thn__Date__c= Date.today() + 10;
        quoteHotelRoomPrice.thn__Quote_Hotel_Room__c = quoteHotelRoomList[0].id;
        quoteHotelRoomPriceList.add(quoteHotelRoomPrice);
        quoteHotelRoomPrice = new thn__Quote_Hotel_Room_Price__c();
        quoteHotelRoomPrice.thn__Date__c= Date.today() + 11;
        quoteHotelRoomPrice.thn__Quote_Hotel_Room__c = quoteHotelRoomList[1].id;
        quoteHotelRoomPriceList.add(quoteHotelRoomPrice);
        insert quoteHotelRoomPriceList;
        PDF_Butler_Settings__c cs = PDF_Butler_Settings__c.getinstance(); 
        cs.Columns_per_Table__c = 5;
         //Sandbox IDs
        cs.datasource_id__c = '00DS800000A8Avh_a0wS8000001hMXl';
        cs.dateDataSource__c = '00DS800000A8Avh_a0wS8000001hMUX';
        cs.priceDataSource__c = '00DS800000A8Avh_a0wS8000001hMSv';
        cs.quantityDataSource__c = '00DS800000A8Avh_a0wS8000001hMPh';
        cs.colWrapperDataSource__c = '00DS800000A8Avh_a0wS8000001hMO5';
        //PROD Ids
        /*cs.datasource_id__c = '00D090000044i9j_a0wJy0000008Y2v';
        cs.dateDataSource__c = '00D090000044i9j_a0wJy0000008Y9N';
        cs.priceDataSource__c = '00D090000044i9j_a0wJy0000008Y69';
        cs.quantityDataSource__c = '00D090000044i9j_a0wJy0000008Y4X';
        cs.colWrapperDataSource__c = '00D090000044i9j_a0wJy000000RhIb';*/
        insert cs;
    }
    @IsTest()
    global static void test_wrapper2List() {

        ColumnRepeaterHotelRoomPricesNewGrid crhrp = new ColumnRepeaterHotelRoomPricesNewGrid();
        //empty
        crhrp.wrapper2List(null);
        //SINGLE
        cadmus_core.SingleWrapper sw = new cadmus_core.SingleWrapper();
        Map<String,String> singleData = new Map<String,String>();
        Map<String, Object> dsMap = new Map<String, Object>();
        sw.data = singleData;

        crhrp.wrapper2List(sw);

        //LIST
        List<thn__Quote_Hotel_Room_Price__c> quoteHotelRoomList = [select id, thn__Quote_Hotel_Room__r.thn__Space_Area__r.Name, thn__Sales_Price_incl_Tax__c, thn__Unit_Price_incl_Tax__c, thn__Sales_Price_excl_Tax__c, thn__Unit_Price_excl_Tax__c, thn__Date__c, thn__Quantity__c, thn__Quote_Hotel_Room__r.thn__Type_of_Occupancy__c from thn__Quote_Hotel_Room_Price__c ORDER BY thn__Quote_Hotel_Room__c, thn__Date__c];
        cadmus_core.ListWrapper lw = new cadmus_core.ListWrapper();
        List<Map<String, Object>> listData = new List<Map<String, Object>>();
        for(thn__Quote_Hotel_Room_Price__c quoteHotelRoom:quoteHotelRoomList){
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(quoteHotelRoom));
            Map<String, Object> newMap = new Map<String, Object>();
            for(String strKey: m.keyset())
            {
                system.debug('strKey'+strKey);
                system.debug('strKey'+m.get(strKey));
                system.debug('strKey'+quoteHotelRoom.thn__Date__c);
                if(strKey.equalsIgnoreCase('thn__Date__c')){
                    system.debug('imhere');
                    newMap.put(strKey,(Date) quoteHotelRoom.thn__Date__c);
                }else{
                    newMap.put(strKey, String.valueof(m.get(strKey)));
                }
            }
            system.debug('mmmmm'+newMap);
            listData.add(newMap);
        }   
        lw.data = listData;

        crhrp.wrapper2List(lw);

        //Any object
        crhrp.wrapper2List(new ColumnRepeaterHotelRoomPricesNewGrid());
        //*********************************************************
        Contact c = new Contact();
        c.FirstName = 'First';
        c.LastName = 'Last';
        c.Email = 'c_first_last@testexample.com';
        insert c;
        
        cadmus_core__Doc_Config__c doc_config = new cadmus_core__Doc_Config__c();
        doc_config.cadmus_core__Document_Title__c = 'TEST';
        doc_config.Name = 'TEST_DOC_CONFIG';
        doc_config.RecordTypeId = Schema.SObjectType.cadmus_core__Doc_Config__c.getRecordTypeInfosByName().get('Main Word Document').getRecordTypeId();
        insert doc_config;
        
        //3 Create Actionable
        cadmus_core__Actionable__c actionable = new cadmus_core__Actionable__c();
        actionable.Name = 'TEST_ACTIONABLE';
        actionable.RecordTypeId = Schema.SObjectType.cadmus_core__Actionable__c.getRecordTypeInfosByName().get('Run Class').getRecordTypeId();
        insert actionable;
        
        Map <String,Object> inputMap = new Map <String,Object> {
            'recordId' => c.Id,
            'userId' => UserInfo.getUserId()
        }; 
        cadmus_core.ConvertController.ConvertDataModel cdm = new cadmus_core.ConvertController.ConvertDataModel();
        cdm.docConfigId = doc_config.Id;
        cdm.objectId = c.Id;
        //cadmus_core.CadmusHttpCalloutMock.setTestCalloutMockSuccess('01I09000001CN3t');
        dsMap.put('00DS800000A8Avh_a0wS8000001hMXl',lw);
        //*********************************************************
        
        crhrp.execute(actionable, doc_config.Id, null, null, dsMap, cdm);
    }
    @IsTest()
    global static void test_execute200() {

        ColumnRepeaterHotelRoomPricesNewGrid crhrp = new ColumnRepeaterHotelRoomPricesNewGrid();


        Map<String, Object> dsMap = new Map<String, Object>();
        cadmus_core.ListWrapper lw = new cadmus_core.ListWrapper();
        List<thn__Quote_Hotel_Room_Price__c> quoteHotelRoomList = [select id, thn__Quote_Hotel_Room__r.thn__Space_Area__r.Name, thn__Sales_Price_incl_Tax__c, thn__Unit_Price_incl_Tax__c,thn__Sales_Price_excl_Tax__c, thn__Unit_Price_excl_Tax__c, thn__Date__c, thn__Quantity__c, thn__Quote_Hotel_Room__r.thn__Type_of_Occupancy__c from thn__Quote_Hotel_Room_Price__c ORDER BY thn__Quote_Hotel_Room__c, thn__Date__c];
        List<Map<String, Object>> listData = new List<Map<String, Object>>();
        for(thn__Quote_Hotel_Room_Price__c quoteHotelRoom:quoteHotelRoomList){
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(quoteHotelRoom));
            Map<String, Object> newMap = new Map<String, Object>();
            for(String strKey: m.keyset())
            {
                system.debug('strKey'+strKey);
                system.debug('strKey'+m.get(strKey));
                system.debug('strKey'+quoteHotelRoom.thn__Date__c);
                if(strKey.equalsIgnoreCase('thn__Date__c')){
                    system.debug('imhere');
                    newMap.put(strKey,(Date) quoteHotelRoom.thn__Date__c);
                }else{
                    newMap.put(strKey, String.valueof(m.get(strKey)));
                }
            }
            system.debug('mmmmm'+newMap);
            listData.add(newMap);
        }   

        Map<String,String> singleData = new Map<String,String>();
        //*********************************************************
        Contact c = new Contact();
        c.FirstName = 'First';
        c.LastName = 'Last';
        c.Email = 'c_first_last@testexample.com';
        insert c;
        
        cadmus_core__Doc_Config__c doc_config = new cadmus_core__Doc_Config__c();
        doc_config.cadmus_core__Document_Title__c = 'TEST';
        doc_config.Name = 'TEST_DOC_CONFIG';
        doc_config.RecordTypeId = Schema.SObjectType.cadmus_core__Doc_Config__c.getRecordTypeInfosByName().get('Main Word Document').getRecordTypeId();
        insert doc_config;
        
        //3 Create Actionable
        cadmus_core__Actionable__c actionable = new cadmus_core__Actionable__c();
        actionable.Name = 'TEST_ACTIONABLE';
        actionable.RecordTypeId = Schema.SObjectType.cadmus_core__Actionable__c.getRecordTypeInfosByName().get('Run Class').getRecordTypeId();
        insert actionable;
        
        Map <String,Object> inputMap = new Map <String,Object> {
            'recordId' => c.Id,
            'userId' => UserInfo.getUserId()
        }; 
        cadmus_core.ConvertController.ConvertDataModel cdm = new cadmus_core.ConvertController.ConvertDataModel();
        cdm.docConfigId = doc_config.Id;
        cdm.objectId = c.Id;
        //*********************************************************

        listData.add(singleData);

        lw.data = listData;
        dsMap.put('00DS800000A8Avh_a0wS8000001hMXl',lw);

        //cadmus_core__Actionable__c actionable = new cadmus_core__Actionable__c();
        //actionable.Get_Url_Field_API_Name__c = 'url';
        //actionable.Get_Url_Parent_Query_Field_Name__c = 'ContentDocument.Id';
        crhrp.execute(actionable, doc_config.Id, null, null, dsMap, cdm);
    }
}