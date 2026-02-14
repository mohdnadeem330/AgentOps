global class ColumnRepeaterHotelRoomPricesNewGrid implements cadmus_core.AbstractBeforeWithDataSourcesActionable{

    global void execute(cadmus_core__Actionable__c actionable, Id docConfig, Id objectId, Map<String, Object> inputMap, Map<String, Object> dataSources, cadmus_core.ConvertController.ConvertDataModel cdm) {
        
        PDF_Butler_Settings__c cs = PDF_Butler_Settings__c.getinstance(); 

        String datasource_id = cs.datasource_id__c;
        String dateDataSource = cs.dateDataSource__c;
        String priceDataSource = cs.priceDataSource__c;
        String quantityDataSource = cs.quantityDataSource__c;
        String colWrapperDataSource = cs.colWrapperDataSource__c;
        
        //Prod IDs
        /*String datasource_id = '00D090000044i9j_a0wJy0000008Y2v';
        String dateDataSource = '00D090000044i9j_a0wJy0000008Y9N';
        String priceDataSource = '00D090000044i9j_a0wJy0000008Y69';
        String quantityDataSource = '00D090000044i9j_a0wJy0000008Y4X';
        String colWrapperDataSource = '00D090000044i9j_a0wJy000000RhIb';*/
        
        //Sandbox IDs
        /*String datasource_id = '00D7Y0000001RUO_a0w7Y00000kKJ0Y';
        String dateDataSource = '00D7Y0000001RUO_a0w7Y00000kKJ0i';
        String priceDataSource = '00D7Y0000001RUO_a0w7Y00000kKJ0d';
        String quantityDataSource = '00D7Y0000001RUO_a0w7Y00000kKpGT';
        String colWrapperDataSource = '00D7Y0000001RUO_a0w7Y00000kKxgV';*/
        
        

        try {


            Object hotelRoomPrice = dataSources.get(datasource_id);
            system.debug('hotelRoomPrice'+hotelRoomPrice);
            List<Map <String, Object>> hotelRoomPrices = wrapper2List(hotelRoomPrice);
            

             system.debug('hotelRoomPrices'+hotelRoomPrices);
             system.debug('hotelRoomPrices'+hotelRoomPrices);

            //Below are the 2 rows for our datasource
            for (Object hPrice : hotelRoomPrices) {
                system.debug('hPrice ------'+hPrice);
            }

            //Create two lists of maps to store values for the columns (roomDates) and the rows (roomPrices)
            //Map<String,Object> price = new Map<String,Object> ();
            List<Map<String, Object>> roomDates = new List<Map<String, Object>> ();
            List<Map<String, Object>> roomPrices = new List<Map<String, Object>> ();
            List<Map<String, Object>> roomQuantities = new List<Map<String, Object>> ();

            //Create a set of dates so that we only keep unique dates
            Set<Date> dateSet = new Set<Date>();
            List<Date> dateList = new List<Date>();

            for (Map<String, Object> line : hotelRoomPrices) {
                System.debug('thn__Date__c'+line.get('thn__Date__c'));
                dateSet.add((Date) line.get('thn__Date__c'));
            }
            dateList.addAll(dateSet);
            system.debug('this is the dateset'+ dateset);
            system.debug('this is the dateList'+ dateList);
            dateList.sort();
            system.debug('this is the dateList sort'+ dateList);
            //Figure out in how many pieces to split the records
            List<Map<String, Object>> colWrappers = new List<Map<String, Object>> ();
            Decimal size = dateList.size();
            System.debug('size dateList = ' + size);
            Integer itemsPerRow = (Integer)cs.Columns_per_Table__c;
            Integer wrapperRows = (Integer) size.divide(itemsPerRow, 0, System.RoundingMode.UP);
            System.debug('size wrapperRows = ' + wrapperRows);
            
            for(Integer i=1;i<=wrapperRows;i++) {
                Map<String, Object> row = new Map<String, Object>();
                row.put('id', 'wrap' + i);
                colWrappers.add(row);
            }
            system.debug('this the colWrappers'+colWrappers);
            System.debug('size wrapperRowscolWrappers = ' +colWrappers.size());
            
            //Loop through the set of unique dates and for every value add it to the roomDates list of maps
            Integer dateCounter = 0;
            Integer dateNr = 1;
            Map<String,Integer> sizeColumnsPerWrap = new Map<String,Integer>();
            for (Date dates : dateList) {
                Map<String, Object> roomDate = new Map<String, Object> ();
                roomDate.put('date', dates);
                roomDate.put('SumQTY', null);
                roomDate.put('parent', 'wrap' + dateNr);
                roomDates.add(roomDate);
                if(!sizeColumnsPerWrap.containsKey('wrap' + dateNr)){
                    sizeColumnsPerWrap.put('wrap' + dateNr,1);
                }else{
                    sizeColumnsPerWrap.put('wrap' + dateNr,sizeColumnsPerWrap.get('wrap' + dateNr)+1);
                }
                dateCounter++;
                if(dateCounter == itemsPerRow) {
                    dateNr++;
                    dateCounter = 0;
                }
            }
            system.debug('this is the roomDates'+roomDates);
            system.debug('sums sizeColumnsPerWrap'+sizeColumnsPerWrap);

            

            //Loop through the quote hotel room price records and create a set of unique thn__Quote_Hotel_Room__c values
            Set<String> quoteHotelRoomSet = new Set<String>();
            Map<String, String> hotelRoomNameMap = new Map<String, String>();
            for (Map<String, Object> op_line : hotelRoomPrices) {
                quoteHotelRoomSet.add((String) op_line.get('thn__Quote_Hotel_Room__c'));
                hotelRoomNameMap.put((String) op_line.get('thn__Quote_Hotel_Room__c')+'name', (String) op_line.get('thn__Quote_Hotel_Room__r.thn__Space_Area__r.Name'));
                hotelRoomNameMap.put((String) op_line.get('thn__Quote_Hotel_Room__c')+'thn__Type_of_Occupancy__c', (String) op_line.get('thn__Quote_Hotel_Room__r.thn__Type_of_Occupancy__c'));

            }
            system.debug('quoteHotelRoomSet = ' + quoteHotelRoomSet);
            system.debug('hotelRoomNameMap = ' + hotelRoomNameMap);

            //Not every quote hotel room price record will have a price for every date
            //To complete the data set we will need to add a price of null for every date that is missing a price
            //First create a map with key = thn__Quote_Hotel_Room__c+thn__Date__c and value = list of thn__Quote_Hotel_Room_Price__c records

            Map<String, List<Map<String, Object>>> priceMap = new Map<String, List<Map<String, Object>>>();
            for (Map<String, Object> op_line : hotelRoomPrices) {
                String key = (String) op_line.get('thn__Quote_Hotel_Room__c') + (Date) op_line.get('thn__Date__c');
                if (priceMap.containsKey(key)) {
                    priceMap.get(key).add(op_line);
                } else {
                    List<Map<String, Object>> priceList = new List<Map<String, Object>>();
                    priceList.add(op_line);
                    priceMap.put(key, priceList);
                }
            }
            system.debug('PriceMap is = ' + PriceMap);
            system.debug('Size PriceMap is = ' + PriceMap.size());

            //Loop through the set of dates and for every date check priceMap to see if there is a price for that date

            System.debug('YQI : wrapperRows ' + wrapperRows);
            Map<String, Object> sums= new Map<String, Object> ();
            Integer priceRowCounter = 0;
            Integer wrapperNbr = 1;
            Integer lineCounter = 1;
            Integer columnCounter = 0;
            Set<String> consumedDates = new Set<String>();
            System.debug('YQI : dateList' + dateList);
            system.debug('quoteHotelRoom'+quoteHotelRoomSet);
            system.debug('roomDate'+dateList);
            system.debug('YQI roomPrices: ' + roomPrices);
            
            Integer counterDateList = 0;    
            Integer dateListSize = dateList.size();
            //Integer loopCounter = 0;
            for (String quoteHotelRoom : quoteHotelRoomSet) {
                system.debug('YQ : quoteHotelRoomSet ----'+ quoteHotelRoomSet);
                system.debug('YQ : quoteHotelRoom ----'+ quoteHotelRoom);
                counterDateList = 0;
                Map<String, Object> price = new Map<String, Object> ();
                //create map with same keys of QTY with quantity add Qty to a map with same key field in the next. line
                // add each time the number with the same key 
                Map<String, Object> quantity = new Map<String, Object> ();
                Integer counter = 1;
                Boolean firstLine = true;
                Integer nullCounter = 0;
                Integer columnRepeaterCounter = 0;
                wrapperNbr = 1;
				Decimal SumPerDay = 0;
                Decimal ValuePerDay = 0;
                for (Date roomDate : dateList) {
                    counterDateList ++;
                    system.debug('roomDate ----'+ roomDate);
                    system.debug('YQ : dateList ----'+ dateList);
                    system.debug('counter '+counter);
                    String key = quoteHotelRoom + roomDate;
                    String roomType;
                    system.debug('zero +  Key'+key);
                    system.debug('zero +  priceMap.get(key)[0]'+priceMap.get(key));
                    system.debug('zero +  priceMap.containsKey(key)'+priceMap.containsKey(key));
                    if (priceMap.containsKey(key)) {
                        Map<String, Object> priceLine = priceMap.get(key)[0];
                        system.debug('zero +  priceLine ---'+priceLine);
                        roomType = (String) priceLine.get('thn__Quote_Hotel_Room__r.thn__Space_Area__r.Name');
                        system.debug('zero +  roomType ---'+roomType);
                        if (firstLine)  {
                            price = new Map<String, Object> ();
                            String typeOfOccupancy = (String) priceLine.get('thn__Quote_Hotel_Room__r.thn__Type_of_Occupancy__c');
                            String shortType = '';
                            if(typeOfOccupancy != null && typeOfOccupancy.equalsIgnoreCase('Single')){
                                shortType = ' SGL';
                            }else if (typeOfOccupancy != null && typeOfOccupancy?.equalsIgnoreCase('Double')){
                                shortType = ' DBL';
                            }else if(typeOfOccupancy != null && typeOfOccupancy?.equalsIgnoreCase('Twin')){
                                shortType = ' TWN';
                            }
                            price.put('FIELD_NAME', priceLine.get('thn__Quote_Hotel_Room__r.thn__Space_Area__r.Name'));
                            price.put('Occupancy',typeOfOccupancy);
                            price.put('parent', 'wrap' + wrapperNbr);
                            system.debug('zero +  parent wrap ---'+wrapperNbr);
                            price.put('VALUE', priceLine.get('thn__Unit_Price_incl_Tax__c'));
							price.put('VALUE_EXCL', priceLine.get('thn__Unit_Price_excl_Tax__c'));
                            price.put('QTY', priceLine.get('thn__Quantity__c'));
							SumPerDay += (Decimal) priceLine.get('thn__Quantity__c') != null ? (Decimal) priceLine.get('thn__Quantity__c') : 0;
                            ValuePerDay += (Decimal) priceLine.get('thn__Unit_Price_incl_Tax__c') != null ? (Decimal) priceLine.get('thn__Unit_Price_incl_Tax__c') : 0 ;
                            Decimal Qty = (Decimal) priceLine.get('thn__Quantity__c') != null ? (Decimal) priceLine.get('thn__Quantity__c') : 0;
                            Decimal qtyFromSum = (Decimal) sums.get('SumQTY_wrap_' + wrapperNbr) != null ? (Decimal)  sums.get('SumQTY_wrap_' + wrapperNbr) : 0;
                            System.debug('zero +  Put HERE ABCD SumQTY_wrap_'+ wrapperNbr + '+' + (qty + qtyFromSum));
                            System.debug('zero +  Qty ABCD ---'+Qty);
                            System.debug('zero +  qtyFromSum ABCD ---'+qtyFromSum);
                            System.debug('zero +  qty + qtyFromSum ABCD ---'+( qty + qtyFromSum));
                            sums.put('SumQTY_wrap_' + wrapperNbr, qty + qtyFromSum);
                            system.debug('zero +  dateListSize --- '+dateListSize);
                            system.debug('zero +  counterDateList --- '+counterDateList);
                            if(dateListSize - counterDateList == 0){    
                                system.debug('I am here  --- ');
								price.put('TotalDay', SumPerDay);
                                price.put('ValueDay', ValuePerDay);
								SumPerDay = 0;
                                ValuePerDay = 0;
                                roomPrices.add(price);  
                            }
                            firstLine = false;
                        } else {
                            system.debug('zero +  priceMap.containsKey : else not first line '+counter);
                            String typeOfOccupancy = (String) priceLine.get('thn__Quote_Hotel_Room__r.thn__Type_of_Occupancy__c');
                            String shortType = '';
                            if(typeOfOccupancy != null && typeOfOccupancy.equalsIgnoreCase('Single')){
                                shortType = ' SGL';
                            }else if (typeOfOccupancy != null && typeOfOccupancy.equalsIgnoreCase('Double')){
                                shortType = ' DBL';
                            }else if(typeOfOccupancy != null && typeOfOccupancy.equalsIgnoreCase('Twin')){
                                shortType = ' TWN';
                            }
                            price.put('VALUE_' + counter, priceLine.get('thn__Unit_Price_incl_Tax__c'));
                            price.put('Occupancy',typeOfOccupancy);
							price.put('VALUE_EXCL_'  + counter, priceLine.get('thn__Unit_Price_excl_Tax__c'));
                            price.put('QTY_' + counter, priceLine.get('thn__Quantity__c'));
							SumPerDay += (Decimal) priceLine.get('thn__Quantity__c') != null ? (Decimal) priceLine.get('thn__Quantity__c') : 0;
                            ValuePerDay += (Decimal) priceLine.get('thn__Unit_Price_incl_Tax__c') != null ? (Decimal) priceLine.get('thn__Unit_Price_incl_Tax__c') : 0 ;
                            Decimal Qty = (Decimal) priceLine.get('thn__Quantity__c') != null ? (Decimal) priceLine.get('thn__Quantity__c') : 0;
                            Decimal qtyFromSum = (Decimal) sums.get('SumQTY_' + counter + '_wrap_' + wrapperNbr) != null ? (Decimal)  sums.get('SumQTY_' + counter + '_wrap_' + wrapperNbr) : 0;
                            System.debug('zero +  Put HERE ABCD else firstline first'+'SumQTY_' + counter + '_wrap_' + wrapperNbr + '+' + (qty + qtyFromSum));
                            System.debug('zero +  Qty ABCD ---'+Qty);
                            System.debug('zero +  qtyFromSum ABCD ---'+qtyFromSum);
                            System.debug('zero +  qty + qtyFromSum ABCD ---'+( qty + qtyFromSum));
                            sums.put('SumQTY_' + counter + '_wrap_' + wrapperNbr, qty + qtyFromSum);
                            system.debug('zero +  parent else wrap ---'+wrapperNbr);
                            counter++;
                            columnRepeaterCounter++;
                            system.debug('zero +  columnRepeaterCounter'+columnRepeaterCounter);
                            system.debug('zero +  itemsPerRow'+itemsPerRow);
                            if(columnRepeaterCounter == itemsPerRow - 1){
                                system.debug('zero +  enter new price');
								price.put('TotalDay', SumPerDay);
                                price.put('ValueDay', ValuePerDay);
								ValuePerDay = 0;
								SumPerDay = 0;
                                roomPrices.add(price);
                                firstline = true;
                                columnRepeaterCounter = 0; 
                                wrapperNbr++;
                                counter = 1;
                            }

                        }
                    } 
                    else {
                        if (firstLine) {
                            system.debug('zero +  firstline'+ counter);
                            String typeOfOccupancy = (String) hotelRoomNameMap.get(quoteHotelRoom+'thn__Type_of_Occupancy__c');
                            String shortType = '';
                            if(typeOfOccupancy != null && typeOfOccupancy.equalsIgnoreCase('Single')){
                                shortType = ' SGL';
                            }else if (typeOfOccupancy != null && typeOfOccupancy.equalsIgnoreCase('Double')){
                                shortType = ' DBL';
                            }else if(typeOfOccupancy != null && typeOfOccupancy.equalsIgnoreCase('Twin')){
                                shortType = ' TWN';
                            }
                            price = new Map<String, Object> ();
                            price.put('FIELD_NAME', hotelRoomNameMap.get(quoteHotelRoom+'name'));
                            price.put('parent', 'wrap' + wrapperNbr);
                            price.put('VALUE', 0);
                            price.put('Occupancy',typeOfOccupancy);
							price.put('VALUE_EXCL', 0);
                            price.put('QTY', 0);
                            Decimal Qty =  0;
                            Decimal qtyFromSum = (Decimal) sums.get('SumQTY_wrap_' + wrapperNbr) != null ? (Decimal)  sums.get('SumQTY_wrap_' + wrapperNbr) : 0;
                            sums.put('SumQTY_wrap_' + wrapperNbr, qty + qtyFromSum);
                            System.debug('zero +  Put HERE ABCD SumQTY_wrap_'+ wrapperNbr + '+' + (qty + qtyFromSum));
                            System.debug('zero +  Qty ABCD ---'+Qty);
                            System.debug('zero +  qtyFromSum ABCD ---'+qtyFromSum);
                            System.debug('zero +  qty + qtyFromSum ABCD ---'+( qty + qtyFromSum));
                            firstLine = false;
                            nullCounter ++;
                        } 
                        else {
                            system.debug('zero + else not firstline'+ counter);
                            price.put('VALUE_' + counter, 0);
							price.put('VALUE_EXCL_' + counter, 0);
                            price.put('Occupancy','');
                            price.put('QTY_' + counter, 0);
                            columnRepeaterCounter++;
                            counter++;
                            system.debug('zero +  columnRepeaterCounter ---'+columnRepeaterCounter);
                            system.debug('zero +  itemsPerRow ---'+itemsPerRow);
                            system.debug('zero +  nullCounter ---'+nullCounter);
                            Decimal Qty =  0;
                            Decimal qtyFromSum =  (Decimal) sums.get('SumQTY_' + counter + '_wrap_' + wrapperNbr) != null ? (Decimal)  sums.get('SumQTY_' + counter + '_wrap_' + wrapperNbr) : 0;
                            sums.put('SumQTY_' + counter + '_wrap_' + wrapperNbr, qty + qtyFromSum);
                            System.debug('zero + Put HERE ABCD else firstline second'+'SumQTY_' + counter + '_wrap_' + wrapperNbr + '+' + (qty + qtyFromSum));
                            //System.debug('Put HERE ABCD SumQTY_wrap_'+ wrapperNbr + '+' + (qty + qtyFromSum));
                            System.debug('zero +  Qty ABCD ---'+Qty);
                            System.debug('zero +  qtyFromSum ABCD ---'+qtyFromSum);
                            System.debug('zero +  qty + qtyFromSum ABCD ---'+( qty + qtyFromSum));
                            if(columnRepeaterCounter == itemsPerRow - 1 && itemsPerRow > nullCounter ){
                                system.debug('enter new price');
								price.put('TotalDay', SumPerDay);
								SumPerDay = 0;
                                price.put('ValueDay', ValuePerDay);
								ValuePerDay = 0;
                                roomPrices.add(price);
                                firstline = true;
                                columnRepeaterCounter = 0; 
                                wrapperNbr++;
                                counter = 1;
                            }
                            nullCounter ++;
                        }
                    }
                    priceRowCounter++;
                    system.debug('zero + Price ---'+price);
                    system.debug('zero + roomPrices ---'+roomPrices);
                }
                //system.debug('Price = '+price);
                system.debug('zero + columnRepeaterCounter --- '+columnRepeaterCounter);
                system.debug('zero + itemsPerRow ---'+itemsPerRow);
                system.debug('zero + nullCounter ---'+nullCounter);
                if(columnRepeaterCounter != 0 && itemsPerRow > nullCounter){
                    system.debug('zero + here');
					price.put('TotalDay', SumPerDay);
					SumPerDay = 0;
                    price.put('ValueDay', ValuePerDay);
								ValuePerDay = 0;
                    roomPrices.add(price);
                }
            }
            system.debug('zero +  YQI roomPrices: '+roomPrices);
            system.debug('zero +  YQI sums: '+ sums);
            Integer ii= 0 ;
            for (Map<String, Object> roomPrice : roomPrices){
                system.debug('zero + roomPrice'+ii+' '+roomPrice);
            }
            List<Object> sumsList = (List<Object>) sums.values();
            List<String> sumsKeysList = new List<String>();
            List<String> sortedList = new List<String>();
            /*****Sorting***/
            for (String element : sums.keySet()) {
                String wrap = element.contains('_') ? element.substring(element.lastIndexOf('_') + 1) : element.substring(7);
                Integer wrapNumber = Integer.valueOf(wrap);
            
                boolean added = false;
                for (Integer i = 0; i < sortedList.size(); i++) {
                    String sortedElement = sortedList[i];
                    String sortedWrap = sortedElement.contains('_') ? sortedElement.substring(sortedElement.lastIndexOf('_') + 1) : sortedElement.substring(7);
                    Integer sortedWrapNumber = Integer.valueOf(sortedWrap);
            
                    if (wrapNumber < sortedWrapNumber) {
                        sortedList.add(i, element);
                        added = true;
                        break;
                    }
                }
            
                if (!added) {
                    sortedList.add(element);
                }
            }
            /********/
            //sumsKeysList.addAll(sums.keySet());
            //sumsKeysList.sort();
            system.debug('sumsKeysList'+sumsKeysList);
            for(String Key: sortedList){
                system.debug('Sums sortedList loop '+Key);
            }
            Integer count = 0 ;
            Map<String, Object> roomQuantity = new Map<String, Object> ();
            String currentWrap = '';
            Integer columnRepeaterCounter = 0;
            system.debug('sums size'+sums.keySet().size());
            
            boolean firstElement = true;
            Integer wrapCounter = 1;
            Integer oPcounter  = 0;
            
            for(String totalKey : sortedList){
                oPcounter++;
                system.debug('*** oPcounter'+oPcounter);
                system.debug('*** start');
                String wrapC =  columnRepeaterCounter ==0 ? 'SumQTY_wrap_'+wrapCounter :'SumQTY_'+columnRepeaterCounter+'_wrap_'+wrapCounter;
                system.debug('*** wrapC '+wrapC);
                if(firstElement){
                    system.debug('*** here 1');
                    roomQuantity = new Map<String, Object> (); 
                    roomQuantity.put('parent', 'wrap' +wrapCounter);
                    roomQuantity.put('FIELD_NAME', 'TOTAL');
                    roomQuantity.put(columnRepeaterCounter == 0 ? 'QTY' : 'QTY_' + columnRepeaterCounter, sums.get(wrapC));
                    firstElement = false;
                    columnRepeaterCounter ++;
                }else{
                    system.debug('*** here 2');
                    System.debug('*** sums.get(wrapC)'+sums.get(wrapC));
                    system.debug('*** here 4');
                    roomQuantity.put(columnRepeaterCounter == 0 ? 'QTY' : 'QTY_' + columnRepeaterCounter, sums.get(wrapC));
                    system.debug('*** here 5');
                    system.debug('*** roomQuantity'+roomQuantity);
                    columnRepeaterCounter ++;
                }
                system.debug('*** here 6'+wrapCounter);
                system.debug('*** columnRepeaterCounter 6'+columnRepeaterCounter);
                if(sizeColumnsPerWrap.get('wrap'+wrapCounter) != null && ( columnRepeaterCounter == sizeColumnsPerWrap.get('wrap'+wrapCounter) || sortedList.size() == oPcounter ) ){
                    system.debug('*** here 7');
                    system.debug('*** Sums YQI Add roomQuantity '+ roomQuantity);
                    roomPrices.add(roomQuantity);
                    columnRepeaterCounter = 0;
                    wrapCounter++;
                    firstElement = true;
                }
                system.debug('*** End');
            }
            /*for (String totalKey : sortedList){
                List<String> key = totalKey.split('_');
                system.debug('Sums key ---'+key);
                system.debug('Sums YQI condition '+!currentWrap.equals(key.get(key.size() - 1)));
                if(!currentWrap.equals(key.get(key.size() - 1))){
                    System.debug('Sums currentWrap ---'+currentWrap);
                    roomQuantity = new Map<String, Object> (); 
                    currentWrap = key.get(key.size() - 1);
                    system.debug('Sums YQI currentWrap ' + currentWrap);
                    roomQuantity.put('parent', 'wrap' + key.get(key.size() - 1));
                    roomQuantity.put('FIELD_NAME', 'TOTAL');
                } else {
                    system.debug('Sums Increment Counter');
                    columnRepeaterCounter++;
                }
                System.debug('Sums YQI key : ' + key + ' QTY : ---' + sums.get(totalKey));
                system.debug('Sums key.size() ---'+key.size());
                if(key.size()==4){
                    roomQuantity.put('QTY_'+ key.get(1), sums.get(totalKey));
                }else { 
                    roomQuantity.put('QTY', sums.get(totalKey));
                }
                system.debug('Sums YQI roomQuanitity: '+ roomQuantity);
                system.debug('Sums columnRepeaterCounter ---'+columnRepeaterCounter);
                system.debug('Sums sizeColumnsPerWrap.get(wrap+currentWrap) - 1 ---'+ (sizeColumnsPerWrap.get('wrap'+currentWrap) - 1));
                system.debug('Sums columnRepeaterCounter == sizeColumnsPerWrap.get(wrap+currentWrap) - 1'+ (columnRepeaterCounter == sizeColumnsPerWrap.get('wrap'+currentWrap) - 1));
                if(columnRepeaterCounter == sizeColumnsPerWrap.get('wrap'+currentWrap) - 1){
                    system.debug('Sums YQI Add roomQuantity '+ roomQuantity);
                    roomPrices.add(roomQuantity);
                    columnRepeaterCounter = 0;
                }
            }*/
            for(Map<String,Object> roomPrice:roomPrices){
                System.debug('Sums roomPrice ----'+roomPrice);
            }
            system.debug('YQI roomPrices: '+roomPrices);
            cadmus_core.ListWrapper columns = new cadmus_core.ListWrapper();
            cadmus_core.ListWrapper rows = new cadmus_core.ListWrapper();  
            cadmus_core.ListWrapper rowsQTY = new cadmus_core.ListWrapper();
            cadmus_core.ListWrapper rowsWrapper = new cadmus_core.ListWrapper();
            
            
            columns.data = roomDates;
            rows.data = roomPrices;
            rowsQTY.data = roomQuantities;
            rowsWrapper.data = colWrappers;
            dataSources.put(dateDataSource, columns);
            dataSources.put(quantityDataSource, rowsQTY);
            dataSources.put(priceDataSource, rows);
            dataSources.put(colWrapperDataSource, rowsWrapper);
            system.debug('!!!! columns' + columns);
            system.debug('!!!! rows' + rows);
            system.debug('!!!! rowsQTY' +rowsQTY);
            
            
            system.debug('!!!! dateDataSource' + dataSources.get(dateDataSource));
            system.debug('!!!! priceDataSource' + dataSources.get(priceDataSource));
            system.debug('!!!! quantityDataSource' + dataSources.get(quantityDataSource));
            

        } catch (Exception e) {
            system.debug('Exception = ' + e);
        }
    }

    global List<Map<String, Object>> wrapper2List(Object wrapper) {
        if (wrapper == null)
            return null;
        List<Map<String,Object>> richFieldsRows = new List<Map<String,Object>> ();
        if (wrapper instanceof cadmus_core.SingleWrapper) {
            cadmus_core.SingleWrapper richFieldsRowsDsSingle = (cadmus_core.SingleWrapper)wrapper;
            
            richFieldsRows.add(richFieldsRowsDsSingle.data);
        } else if (wrapper instanceof cadmus_core.ListWrapper) {
            cadmus_core.ListWrapper richFieldsRowsDsSingle = (cadmus_core.ListWrapper)wrapper;
            richFieldsRows.addAll(richFieldsRowsDsSingle.data);
            
        } else {
            richFieldsRows = null;
        }

        return richFieldsRows;
       
    }

    global List<Map<String, Object>> wrapper2List1(Object wrapper) {
        if (wrapper == null)
            return null;
        List<Map<String,Object>> richFieldsRows = new List<Map<String,Object>> ();
        if (wrapper instanceof cadmus_core.SingleWrapper) {
            cadmus_core.SingleWrapper richFieldsRowsDsSingle = (cadmus_core.SingleWrapper)wrapper;
            
            richFieldsRows.add(richFieldsRowsDsSingle.data);
        } else if (wrapper instanceof cadmus_core.ListWrapper) {
            cadmus_core.ListWrapper richFieldsRowsDsSingle = (cadmus_core.ListWrapper)wrapper;
            richFieldsRows.addAll(richFieldsRowsDsSingle.data);
            
        } else {
            richFieldsRows = null;
        }

        return richFieldsRows;
       
    }


}