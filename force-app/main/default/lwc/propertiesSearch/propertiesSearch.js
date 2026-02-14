import { LightningElement, wire, track } from "lwc";
import { getRecord } from 'lightning/uiRecordApi';
import getUnitQuery from "@salesforce/apex/UnitService.getUnitQuery";
import prepareDropdownData from "@salesforce/apex/UnitService.prepareDropdownData";
import getAllocationGroupQuery from "@salesforce/apex/AllocationGroupService.getAllocationGroupQuery";
import getAllocationGroupUsersQuery from "@salesforce/apex/AllocationGroupUserService.getAllocationGroupUsersQuery";
import prepareLocationNames from "@salesforce/apex/BuildingSectionService.prepareLocationNames";
import getUsersQuery from "@salesforce/apex/UserService.getUsersQuery";
import updateUnit from "@salesforce/apex/UnitSearchController.updateUnit";
import getBlockedReasonsByUserRole from "@salesforce/apex/UnitSearchController.getBlockedReasonsByUserRole";
import userId from '@salesforce/user/Id';
import usersRoleName from '@salesforce/schema/User.UserRole.Name';
import usersProfileName from '@salesforce/schema/User.Profile.Name';
import restrictedBlockedReasons from '@salesforce/label/c.RestrictedBlockedReasons';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import lightningdatatableHideColumn from '@salesforce/resourceUrl/lightningdatatableHideColumn'
import {loadStyle} from 'lightning/platformResourceLoader'
import hasNewUnitStatusVisiblePermission from '@salesforce/customPermission/New_UnitStatus_Visible';



//hidden column for the Id
const mainColumns = [
    { label: 'Unit Code', fieldName: 'linkName', type: 'url',  sortable: "true" ,
    typeAttributes: {label: { fieldName: 'Name' }, target: '_blank', tooltip: { fieldName: 'Name' }, sortable: "true" }},
    { label: 'Status', fieldName: 'Status__c', sortable: "true" },
    { label: 'Rooms', fieldName: 'TotalRooms__c', sortable: "true" },
    { label: 'Unit Category', fieldName: 'UnitCategory__c', sortable: "true" },
    //{ label: 'Total Area', fieldName: 'TotalArea__c' },
    { label: 'Saleable Area', fieldName: 'SaleableArea__c', sortable: "true" },
   // { label: 'Balcony Area', fieldName: 'TerraceArea__c', sortable: "true" },
    { label: 'Selling Price', fieldName: 'SellingPrice', sortable: "true"},
    { label: 'Assigned To', fieldName: 'AllocationGroupUser__c', sortable: "true" },
    //{ label: 'Unit View', fieldName: 'UnitView__c', sortable: "true" },
    { label: '', fieldName: 'Id', initialWidth: 5, cellAttributes: { class:'column-id' /*important for reponsive */} }

    //{ label: 'Reservation Fee', fieldName: 'OnlineReservationFee__c' },
];

export default class PropertiesSearch extends LightningElement {
    @track columns = mainColumns;
    @track sortBy;
    @track sortDirection;
    propertyStatusPickListValuesWtONew = [
        {label: "All", value: 'All' },
        {label: "Available", value: 'Available' },
        {label: "Blocked", value: 'Blocked' },
    ];
    propertyStatusPickListValuesWtNew = [
        {label: "All", value: 'All' },
        {label: "New", value: 'New' },
        {label: "Available", value: 'Available' },
        {label: "Blocked", value: 'Blocked' }
    ];
    propertyStatusPickListValuesUpdate = [
        {label: "Available", value: 'Available' },
        {label: "Blocked", value: 'Blocked' }
    ];
    yesNoValuesPickListValues = [
        {label: "Yes", value: 'true' },
        {label: "No", value: 'false' }
    ];
    floorNumberPickListValues;
    unitViewPickListValues;
    blockedReasonPickListValues;
    blockedReasonSearchPickListValues;
    @track blockerForReadOnly = false;
    restrictedBlockedReasonsLabel = restrictedBlockedReasons;
    assignedtoUserGroupListValues = [
        {label: "None", value: 'None' },
        {label: "Assign to User", value: 'User' },
        {label: "Assign to Allocation Group", value: 'Group' }
    ];
    projectNamePickListValues;
    userRoleName;
    userProfileName;
    propertyStatusField;
    unitCodeField;
    unitViewField;
    blockedReasonSearchField; 
    multiPurposeRoomField;
    unitFinishesField;
    blockedBySearchField;
    locationNamePickListValues = [];
    numberOfRoomsPickListValues = [];
    handoverZonePickListValues = [];
    unitCategoryPickListValues = [];
    isLoading=false;
    @track selectedDatatableRows = [];
    usersPickListValues = [];
    blockedByPickListValues = [];
    blockedByFilterPickListValues = [];
    usersPickListFilterValues = [];
    allocationGroupPickListValues = [];
    rowsTableData = [];
    rowsTableDataBlockedby = [];
    doneTypingInterval = 0;
    @track updatePropertyButtonVisibility = false;
    @track assignmentActionsButtonVisibility = false;
    @track loggedinUserID ='';
    @track updateUnitModal = false;
    @track isAvailableModalOpen = false;
    @track blockFieldsVisibility = false;
    @track assignedtoGroupVisibility = false;
    @track assignedtoUserVisibility = false;
    @track data;
    @track updateUnitAlertLabelValue = '';
    @track totalUnits = 0;


    @wire(getRecord, {recordId: userId, fields: [usersRoleName, usersProfileName]}) 
    wireuser({error,data}) {
    if (error) {
        this.error = error; 
    } else if (data) {
        if(data.fields.UserRole.value){
            this.userRoleName=data.fields.UserRole.value.fields.Name.value;
        }
        this.userProfileName=data.fields.Profile.value.fields.Name.value; 
        this.resetAll();
       }
    }

    renderedCallback(){ 
        if(this.isCssLoaded) return
        this.isCssLoaded = true
        loadStyle(this, lightningdatatableHideColumn).then(()=>{
            // console.log("Loaded Successfully");
        }).catch(error=>{ 
            // console.error("Error in loading the css");
        })
    }

    get hasNewUnitStatusVisiblePermission(){
        return hasNewUnitStatusVisiblePermission;
    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleRoomChange(event) {
        this[event.target.name] = ' ' + event.target.value ;
    }

    handleSortdata(event) {
        // field name
        this.sortBy = event.detail.fieldName;

        // sort direction
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }

    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.data));
        // Return the value stored in the field
        let keyValue = (a) => {
            if (fieldname = 'SellingPrice') {

                let value = this.sellingPriceSorting(a[fieldname]);
                return value;
            }else{
                return a[fieldname];
            }
        };

        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // set the sorted data to data table data
        this.data = parseData;

    }

    handleKeyUp(event) {
        clearTimeout(this.typingTimer);
        let value = event.target.value;
        let name = event.target.name;

        this.typingTimer = setTimeout(() => {
            this[name] = value;
        }, this.doneTypingInterval);       
    }

    handleSuccessAssignedToAllocationGroup(event){
        this[event.target.name] = event.target.value;

        if (event.target.value == 'Group' ){
            this.assignedtoGroupVisibility = true;
            this.assignedtoUserVisibility = false;
        } else if (event.target.value == 'User' ){
            this.assignedtoGroupVisibility = false;
            this.assignedtoUserVisibility = true;
        }else{
            this.assignedtoGroupVisibility = false;
            this.assignedtoUserVisibility = false;
        }
    }
    
    handleSuccessBlockedFields(event){
        this[event.target.name] = event.target.value;

        if (event.target.value == 'Blocked' ){
            this.blockFieldsVisibility = true;
        } else {
            this.blockFieldsVisibility = false;
        }
    }

    async handleProjectChange(event) {
        this[event.target.name] = event.target.value;
        this.getDropDownData();
    }

    async handleSearchAll(event) {
        this.isLoading=true;

        let newTableData = [];
        
        var condition = (this.buildingNameField !== '' && this.buildingNameField !== null && this.buildingNameField !== undefined
          ? 'BuildingSectionName__c =\'' + this.buildingNameField +'\'': '');
          
          condition += (this.unitCodeField !== '' && this.unitCodeField !== null && this.unitCodeField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            ' Name LIKE \'' +
            '%' +
            this.unitCodeField +
            '%\''
          : '');

          condition += (this.unitViewField !== '' && this.unitViewField !== null && this.unitViewField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            ' UnitView__c LIKE \'' +
            '%' +
            this.unitViewField +
            '%\''
          : '');

          condition += (this.propertyStatusField !== '' && this.propertyStatusField !== null && this.propertyStatusField !== 'All' && this.propertyStatusField  !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            ' Status__c  LIKE \'' +
            '%' +
            this.propertyStatusField +
            '%\''
          : (hasNewUnitStatusVisiblePermission ? (condition !== '' && condition !== null ? ' AND ' : '') + '(Status__c =  \'New\' OR Status__c =  \'Available\' OR Status__c =  \'Blocked\')'  : (condition !== '' && condition !== null ? ' AND ' : '') + '(Status__c =  \'Available\' OR Status__c =  \'Blocked\')'));
          
          condition += (this.floorNumberField !== '' && this.floorNumberField !== null && this.floorNumberField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            ' FloorNumber__c LIKE \'' +
            '%' +
            this.floorNumberField +
            '%\''
          : '');

          condition += (this.totalRoomsField !== '' && this.totalRoomsField !== null && this.totalRoomsField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
          ' TotalRooms__c =\'' + this.totalRoomsField +'\'': '');
           

          condition += (this.handoverZoneField !== '' && this.handoverZoneField !== null && this.handoverZoneField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            ' HandoverZone__c LIKE \'' +
            '%' +
            this.handoverZoneField +
            '%\''
          : '');

          condition += (this.unitCategoryField !== '' && this.unitCategoryField !== null && this.unitCategoryField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
          'UnitCategory__c =\'' + this.unitCategoryField +'\'': ''); 

          condition += (this.projectNameField !== '' && this.projectNameField !== null && this.projectNameField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            ' Project__r.Name LIKE \'' +
            '%' +
            this.projectNameField +
            '%\''
          : '');

          condition += (this.assignedToField !== '' && this.assignedToField !== null && this.assignedToField !== undefined && this.assignedToField !== 'Unassigned'
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            'AllocationGroupUser__c  =\'' + this.assignedToField +'\'': '');

            condition += ( this.assignedToField == 'Unassigned'
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            'AssignedToUser__c  = null AND AllocationGroupName__c = null': '');

          condition += (this.blockedBySearchField !== '' && this.blockedBySearchField !== null && this.blockedBySearchField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            'BlockedBy__c  =\'' + this.blockedBySearchField +'\'': '');

            condition += (this.blockedReasonSearchField !== '' && this.blockedReasonSearchField !== null && this.blockedReasonSearchField !== undefined
         ? (condition !== '' && condition !== null ? ' AND ' : '') +
            'BlockedReason__c  =\'' + this.blockedReasonSearchField +'\'': '');

           condition += (this.multiPurposeRoomField !== '' && this.multiPurposeRoomField !== null && this.multiPurposeRoomField !== undefined
           ? (condition !== '' && condition !== null ? ' AND ' : '') +
             'BuildingSectionName__r.EligibileforMultiPurposeRoom__c =' + (this.multiPurposeRoomField == 'true' ? true : false) : '');

           condition += (this.unitFinishesField !== '' && this.unitFinishesField !== null && this.unitFinishesField !== undefined
           ? (condition !== '' && condition !== null ? ' AND ' : '') +
             'BuildingSectionName__r.EligibleforUnitFinishes__c =' +(this.unitFinishesField == 'true' ? true : false) : '');

          condition += (condition !== '' && condition !== null ? ' AND ' : '') + 'PropertyStatus__c = \'Sale\' ';
            
        var blockedReasonCondition = '';
        if (this.userProfileName != 'System Administrator' && this.restrictedBlockedReasonsLabel != undefined && this.restrictedBlockedReasonsLabel != null && this.restrictedBlockedReasonsLabel != '') {
            blockedReasonCondition += ' AND (';
            if (this.restrictedBlockedReasonsLabel.includes(',')) {
                let restrictedBlockedReasonsList = this.restrictedBlockedReasonsLabel.split(',');
                for (let i = 0; i < restrictedBlockedReasonsList.length; i++) {
                    blockedReasonCondition += "BlockedReason__c !=  '" + restrictedBlockedReasonsList[i].trim() + "'";
                    if (i != (restrictedBlockedReasonsList.length - 1)) {
                        blockedReasonCondition += " AND ";
                    }
                }
            } else {
                blockedReasonCondition += "BlockedReason__c !=  '" + this.restrictedBlockedReasonsLabel.trim() + "'";
            }
            blockedReasonCondition += ') ';
        }

        var query;
        if (condition !== '' || condition !== null || condition !== undefined ) {
            query = 'SELECT Id,Name,AffectionPlan__c,CurrencyIsoCode,BlockedByName__c,Status__c,TotalRooms__c,BlockedByUserRoleName__c,AssignedToUser__c,AllocationGroupName__c,AllocationGroup__c,BlockedReason__c,UnitCategory__c,BlockedBy__c,BlockedComments__c,SellingPrice__c,TotalArea__c,AllocationGroupUser__c,SaleableArea__c,TerraceArea__c,UnitView__c,OnlineReservationFee__c,MarketingPlan__c,BuildingSectionName__c FROM Unit__c WHERE ' +
            condition + blockedReasonCondition;
        }else{
            query = 'SELECT Id,Name,AffectionPlan__c,CurrencyIsoCode,BlockedByName__c,BlockedByUserRoleName__c,Status__c,TotalRooms__c,AssignedToUser__c,AllocationGroupName__c,AllocationGroup__c,UnitCategory__c,BlockedReason__c,BlockedBy__c,BlockedComments__c,SellingPrice__c,TotalArea__c,AllocationGroupUser__c,SaleableArea__c,TerraceArea__c,UnitView__c,OnlineReservationFee__c,MarketingPlan__c,BuildingSectionName__c FROM Unit__c WHERE PropertyStatus__c = \'Sale\' AND (Status__c =  \'Available\' OR Status__c =  \'Blocked\')' + blockedReasonCondition;
        }

        const newData = await getUnitQuery({query:query});

        newData.forEach(record => {
            record.linkName = '/'+record.Id;
            if (record.SellingPrice__c !== undefined && record.SellingPrice__c !== null &&record.SellingPrice__c !== '' ) {
                record.SellingPrice = record.CurrencyIsoCode + ' ' + this.numberWithCommas(record.SellingPrice__c);
            }else{
                record.SellingPrice = ' ';
            }
        });
            for (let i = 0; i < newData.length; i++) {
            newTableData.push(newData[i]);
        }

        if (this.propertyStatusField == 'Blocked' || (this.blockedReasonSearchField !== '' && this.blockedReasonSearchField !== null && this.blockedReasonSearchField !== undefined) || (this.blockedBySearchField !== '' && this.blockedBySearchField !== null && this.blockedBySearchField !== undefined)){
            this.columns = [
                { label: 'Unit Code', fieldName: 'linkName', type: 'url', sortable: "true" ,
                typeAttributes: {label: { fieldName: 'Name' }, target: '_blank', tooltip: { fieldName: 'Name' } ,sortable: "true"}},
                { label: 'Status', fieldName: 'Status__c', sortable: "true"},
                { label: 'Rooms', fieldName: 'TotalRooms__c', sortable: "true" },
                { label: 'Unit Category', fieldName: 'UnitCategory__c', sortable: "true" },
                //{ label: 'Total Area', fieldName: 'TotalArea__c' },
                { label: 'Saleable Area', fieldName: 'SaleableArea__c', sortable: "true" },
                { label: 'Balcony Area', fieldName: 'TerraceArea__c', sortable: "true" },
                { label: 'Selling Price', fieldName: 'SellingPrice', sortable: "true"},
                { label: 'Allocation Group/User', fieldName: 'AllocationGroupUser__c', sortable: "true" },
                { label: 'Unit View', fieldName: 'UnitView__c', sortable: "true" },
                //{ label: 'Reservation Fee', fieldName: 'OnlineReservationFee__c' },
                { label: 'Blocked By', fieldName: 'BlockedByName__c', sortable: "true" },
                { label: 'Blocked Reason', fieldName: 'BlockedReason__c', sortable: "true" },
                { label: 'Blocked Comments', fieldName: 'BlockedComments__c', sortable: "true" },
                { label: '', fieldName: 'Id', initialWidth: 5, cellAttributes: { class:'column-id' /*important for reponsive */} }
            ];
        }else {
            this.columns = mainColumns;
        }
        if (newTableData.length < 1) {
            const evt = new ShowToastEvent({
                title: 'Unit Search',
                message: 'No Units found' ,
                variant: 'error',
            });
            this.dispatchEvent(evt);
        }
        this.data = newTableData;
        this.totalUnits = newTableData.length;
        
        this.isLoading=false;
    }

    numberWithCommas(x) {
        x= x + '';
        return x.replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",");
    }

    sellingPriceSorting(x) {
        x= x + '';
        x=x.replaceAll(',', "");
        x=x.replace('AED', "");
        x=Number(x);
        return x;
    }

    async handleRowAction(event) {
        
        this.rowsTableData =[];
        let selectedRowsArray = [];

        var selectedRows = event.detail.selectedRows;

        // console.log(selectedRows.length);
        for (let index = 0; index < selectedRows.length; index++) {

            if (this.userProfileName == 'System Administrator' && (selectedRows[index].BlockedReason__c == 'CANCELLATION-LEGAL RESTRICTION' || selectedRows[index].BlockedReason__c ==  'DEV RESTRICTION')) {
                selectedRowsArray = [...selectedRowsArray, selectedRows[index].Name]; 
                this.rowsTableData.push(selectedRows[index].Id);
            }else{
                selectedRowsArray = [...selectedRowsArray, selectedRows[index].Name]; 
                this.rowsTableData.push(selectedRows[index].Id);
            }
        }
        this.selectedDatatableRows = selectedRowsArray;

        if (selectedRowsArray.length > 0) {
            this.updatePropertyButtonVisibility = true;
        }else{
            this.updatePropertyButtonVisibility = false;
        }
        
    }

    async resetAll() {
        this.isLoading=true;
        // console.log('resetall');

        this.buildingNameField= '';
        this.floorNumberField= '';
        this.unitCodeField= '';
        this.unitViewField = '';
        this.totalRoomsField= '';
        this.assignedToField= '';
        this.projectNameField= '';
        this.unitCategoryField= '';
        this.handoverZoneField= '';
        this.multiPurposeRoomField= '';
        this.unitFinishesField= ''; 
        this.blockedReasonSearchField= ''; 
        this.blockedBySearchField= ''; 
        this.selectedDatatableRows = [];
        this.updatePropertyButtonVisibility = false;
        this.assignmentActionsButtonVisibility = false;
        this.assignedtoGroupVisibility = false;
        this.assignedtoUserVisibility = false;
        this.blockFieldsVisibility = false;
        this.columns = mainColumns;

        let newTableData = [];
        let query;

            query = 'SELECT Id,Name,AffectionPlan__c,BlockedByName__c,BlockedByUserRoleName__c,CurrencyIsoCode,Status__c,TotalRooms__c,AssignedToUser__c,AllocationGroupName__c,AllocationGroup__c,UnitCategory__c,BlockedReason__c,BlockedBy__c,BlockedComments__c,SellingPrice__c,TotalArea__c,SaleableArea__c,TerraceArea__c,AllocationGroupUser__c,UnitView__c,OnlineReservationFee__c,MarketingPlan__c,BuildingSectionName__c FROM Unit__c WHERE PropertyStatus__c = \'Sale\' AND (Status__c =  \'Available\' OR Status__c =  \'Blocked\') ';
            // console.log(query);
        const newData = await getUnitQuery({query:query});
        newData.forEach(record => {
            record.linkName = '/'+record.Id;
            if (record.SellingPrice__c !== undefined && record.SellingPrice__c !== null &&record.SellingPrice__c !== '' ) {
                record.SellingPrice = record.CurrencyIsoCode + ' ' + this.numberWithCommas(record.SellingPrice__c);
            }else{
                record.SellingPrice = ' ';
            }
            
           
        });
        for (let i = 0; i < newData.length; i++) {
            newTableData.push(newData[i]);
                }
        this.data = newTableData;
        this.totalUnits = newTableData.length;

        const lwcComboboxFields = this.template.querySelectorAll(
            'lightning-combobox'
        );
        if (lwcComboboxFields) {
            lwcComboboxFields.forEach(field => {
                if (field.name == 'propertyStatusField') {
                    field.value = 'All';
                } else {
                    field.value = null;
                }
            });
        }

        const lwcInputFields = this.template.querySelectorAll(
            'lightning-input'
        );
        if (lwcInputFields) {
            lwcInputFields.forEach(field => {
                field.value = '';
            });
        }

        if (this.userRoleName != null && this.userRoleName.indexOf('Head of Sales') != -1) {
            this.blockerForReadOnly = true;
            this.assignedtoUserGroupListValues = [
                {label: "None", value: 'None' },
                {label: "Assign to User", value: 'User' },
                {label: "Assign to Allocation Group", value: 'Group' }
            ];
        }else{
            this.blockerForReadOnly = false;
            this.assignedtoUserGroupListValues = [
                {label: "None", value: 'None' },
                {label: "Assign to User", value: 'User' },
                {label: "Assign to Allocation Group", value: 'Group' }
            ];
        }

        
        this.getDropDownData();
        this.isLoading=false;
    }
    
    async connectedCallback() {
        this.loggedinUserID = userId;
    }

    async getDropDownData(){

        let TotalRoomsData = [];
        let UnitCategoryData = [];
        let HandoverZoneData = [];
        let floorNumberData = [];
        let unitViewData = [];
        let projectNameData = [];
        let dropdownData = [];
        let newLocationNamesDataTableData = [];
        let newLocationNamesData = [];

        if (this.projectNameField == '' || this.projectNameField == null || this.projectNameField == undefined ) {
            dropdownData = await prepareDropdownData();

            for (let i = 0; i < dropdownData.length; i++)
            {
                if (dropdownData[i].Project__r.Name) {
                projectNameData.push({ label: dropdownData[i].Project__r.Name, value: dropdownData[i].Project__r.Name });
                }
            }

            this.projectNamePickListValues = this.sortDropDownData(projectNameData,false,true); 

            let newUserRoleDataSet = [];
            let newAssignedToFilterDataSet = [];
            let userRoleQuery;


            if (this.userRoleName != null && this.userRoleName.indexOf('Head of Sales') != -1) {
                userRoleQuery = 'SELECT Id,Name FROM User WHERE  ((RoleName__c LIKE \'%Sales Manager%\' AND IsActive = true AND ManagerId = \'' + this.loggedinUserID + '\') OR id = \'' + this.loggedinUserID + '\')';
            }else{
                userRoleQuery = 'SELECT Id,Name FROM User WHERE  RoleName__c LIKE \'%Sales Manager%\' AND IsActive = true ';
            }
            
            console.log(userRoleQuery);
            let newUserRoleData = await getUsersQuery({query:userRoleQuery});

            for (let i = 0; i < newUserRoleData.length; i++)
            {
                newUserRoleDataSet.push({ label: newUserRoleData[i].Name, value: newUserRoleData[i].Id });
                newAssignedToFilterDataSet.push({ label: newUserRoleData[i].Name, value: newUserRoleData[i].Name });
            }
            this.usersPickListValues = this.sortDropDownData(newUserRoleDataSet,false,false);

            let newBlockedByDataSet = [];
            let userBlockedByQuery;

            if (this.userRoleName != null && this.userRoleName.indexOf('Head of Sales') != -1) {
                userBlockedByQuery = 'SELECT Id,Name FROM User WHERE ((RoleName__c LIKE \'%Sales Manager%\' AND IsActive = true AND (ManagerId = \'' + this.loggedinUserID + '\' OR Manager.ManagerId = \'' + this.loggedinUserID + '\')) OR id = \'' + this.loggedinUserID + '\')';
            }else{
                userBlockedByQuery = 'SELECT Id,Name,ProfileName__c FROM User WHERE  (RoleName__c LIKE \'%Head of Sales%\' OR RoleName__c LIKE \'%Director of Sales%\' OR RoleName__c LIKE \'%CASA VP%\' OR RoleName__c LIKE \'%Sales Support%\' OR id = \'' + this.loggedinUserID + '\') AND IsActive = true ';
            }
            // console.log(userBlockedByQuery);

            const newBlockedByData = await getUsersQuery({query:userBlockedByQuery});
            for (let i = 0; i < newBlockedByData.length; i++)
            {
                newBlockedByDataSet.push({ label: newBlockedByData[i].Name, value: newBlockedByData[i].Id });
            }
            this.blockedByFilterPickListValues = this.sortDropDownData(newBlockedByDataSet,false,true);
            this.blockedByPickListValues = this.sortDropDownData(newBlockedByDataSet,false,false);

            let allocationGroupquery;
            let newAllocationGroupDataSet = [];

            if (this.userRoleName != null && this.userRoleName.indexOf('Head of Sales') != -1) {
                //allocationGroupquery = 'Select AllocationGroup__r.Id,AllocationGroup__r.Name FROM AllocationGroupUser__c WHERE User__r.ManagerId= \'' + this.loggedinUserID + '\' AND AllocationGroup__r.IsActive__c = true';

                allocationGroupquery = 'Select AllocationGroup__r.Id,AllocationGroup__r.Name FROM AllocationGroupUser__c WHERE (User__r.ManagerId= \'' + this.loggedinUserID + '\' OR User__r.Manager.ManagerId= \'' + this.loggedinUserID + '\') AND AllocationGroup__r.IsActive__c = true';
                
                newAllocationGroupDataSet = [];
                const newAllocationGroupData = await getAllocationGroupUsersQuery({query:allocationGroupquery});
                for (let i = 0; i < newAllocationGroupData.length; i++)
                {
                    newAllocationGroupDataSet.push({ label: newAllocationGroupData[i].AllocationGroup__r.Name, value: newAllocationGroupData[i].AllocationGroup__r.Id });
                    newAssignedToFilterDataSet.push({ label: newAllocationGroupData[i].AllocationGroup__r.Name, value: newAllocationGroupData[i].AllocationGroup__r.Name });

                }
            }
            else{
                allocationGroupquery = 'SELECT Id,Name FROM AllocationGroup__c WHERE IsActive__c = true ';
                newAllocationGroupDataSet = [];
                const newAllocationGroupData = await getAllocationGroupQuery({query:allocationGroupquery});
                for (let i = 0; i < newAllocationGroupData.length; i++)
                {
                    newAllocationGroupDataSet.push({ label: newAllocationGroupData[i].Name, value: newAllocationGroupData[i].Id });
                    newAssignedToFilterDataSet.push({ label: newAllocationGroupData[i].Name, value: newAllocationGroupData[i].Name });

                }
            }
            
            this.allocationGroupPickListValues = this.sortDropDownData(newAllocationGroupDataSet,false,false);
            this.usersPickListFilterValues = this.sortDropDownData(newAssignedToFilterDataSet,true,true);


            let newBlockedReasonsDataSet = [];

            const newBlockedReasonsData = await getBlockedReasonsByUserRole({userProfile:this.userProfileName}) ;
            for (let i = 0; i < newBlockedReasonsData.length; i++)
            {
                newBlockedReasonsDataSet.push({ label: newBlockedReasonsData[i], value: newBlockedReasonsData[i] });
            }
            this.blockedReasonPickListValues = this.sortDropDownData(newBlockedReasonsDataSet,false,false);
            this.blockedReasonSearchPickListValues = this.sortDropDownData(newBlockedReasonsDataSet,false,true);



        } else {
            dropdownData = await prepareDropdownData({projectNameParam :this.projectNameField});
            newLocationNamesData = await prepareLocationNames({projectName :this.projectNameField}) ;
            for (let i = 0; i < newLocationNamesData.length; i++)
            {
                newLocationNamesDataTableData.push({ label: newLocationNamesData[i].Name, value: newLocationNamesData[i].Id });
            }
        }

        for (let i = 0; i < dropdownData.length; i++)
        {
            if (dropdownData[i].TotalRooms__c) {
                TotalRoomsData.push({ label: dropdownData[i].TotalRooms__c + '', value: dropdownData[i].TotalRooms__c+ '' });
            }
            if (dropdownData[i].UnitCategory__c) {
                UnitCategoryData.push({ label: dropdownData[i].UnitCategory__c, value: dropdownData[i].UnitCategory__c });
            }
            if (dropdownData[i].HandoverZone__c) {
                    HandoverZoneData.push({ label: dropdownData[i].HandoverZone__c, value: dropdownData[i].HandoverZone__c });
            }
            if (dropdownData[i].FloorNumber__c) {
                floorNumberData.push({ label: dropdownData[i].FloorNumber__c, value: dropdownData[i].FloorNumber__c });
            } 
            if (dropdownData[i].UnitView__c) {
                unitViewData.push({ label: dropdownData[i].UnitView__c, value: dropdownData[i].UnitView__c });
            }
        }

        this.locationNamePickListValues = this.sortDropDownData(newLocationNamesDataTableData,false,true);
        this.numberOfRoomsPickListValues = this.sortDropDownData(TotalRoomsData,false,true);
        this.handoverZonePickListValues = this.sortDropDownData(HandoverZoneData,false,true);
        this.unitCategoryPickListValues = this.sortDropDownData(UnitCategoryData,false,true);
        this.floorNumberPickListValues = this.sortDropDownData(floorNumberData,false,true);
        this.unitViewPickListValues = this.sortDropDownData(unitViewData,false,true);


    }

    sortDropDownData(fieldname,assignedToFlag,noneFlag) {
        let parseData = JSON.parse(JSON.stringify(fieldname));
        let filteredSortedData= [];
        const filteredData = parseData.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);


        let keyValue = (a) => {
            return a['label'];
        };
        
        filteredData.sort((x, y) => {
            if (x !== 'None' && y !== 'None') {
                x = keyValue(x) ? keyValue(x) : ''; 
                y = keyValue(y) ? keyValue(y) : '';
                return  ((x > y) - (y > x));
            }
        });
        if (noneFlag) {
            filteredSortedData.push({ label: "None", value: null });
        }
        if (assignedToFlag) {
            filteredSortedData.push({ label: "Unassigned", value: 'Unassigned' });
        }
        filteredData.forEach(element => {
            filteredSortedData.push({ label: element.label, value: element.value });
        });

        return filteredSortedData
    }
    

    openUpdateModal(event) {
        // console.log('onsuccess: ', this.propertyStatusField);
        this.updateUnitModal = true;
        this.statusFieldVisibility = true;
        this.blockedByField = this.loggedinUserID;
        


        // if (this.propertyStatusField == 'Blocked') {
        //     this.blockFieldsVisibility = true;
        //     this.updatePropertyStatusField = 'Blocked';
        // }else if (this.PropertyStatusField == 'Available') {
        //     this.blockFieldsVisibility = false;
        //     this.updatePropertyStatusField = 'Available';
        // }
    }

    openAssignModal(event) {
        this.blockFieldsVisibility = false;
        this.statusFieldVisibility = false;
        this.updateUnitModal = true;
    }

    closeModal() {
        this.updateUnitModal = false;
        this.assignedtoGroupVisibility = false;
        this.assignedtoUserVisibility = false;
        this.updateUnitAlertLabelValue = '';
        this.assignedtoGroupVisibility = false;
        this.assignedtoUserVisibility = false;
        this.blockFieldsVisibility = false;
        this.isLoading=false;
        this.updatePropertyStatusField = ''

    }

    async submitDetails() {
        this.isLoading=true;
        
        this.updateUnitAlertLabelValue = '';
        if (this.statusFieldVisibility == false) {
            this.blockFieldsVisibility = false;
            if (this.assignedtoGroupVisibility == false && this.assignedtoUserVisibility == false) {
                this.updateUnitModal = false;
                this.updateUnitAlertLabelValue = '';
                try{
                    await updateUnit({allocationGroup:'null', assignedTo:'null', propertyStatus:'', blockedReason:this.blockedReasonField , idList:this.rowsTableData, comments:this.blockedCommentsField, blockedBy:this.blockedByField, blockedDate:'null'})
                    const evt = new ShowToastEvent({
                        title: 'Unit Assignment',
                        message: 'Unit/s assigned successfully ',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                }
                catch(e){
                    const evt = new ShowToastEvent({
                        title: 'Unit Assignment',
                        message: 'Unit/s assignment failed ' + JSON.stringify(e),
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }
                // this.resetAll();
                this.handleSearchAll();


            } else if (this.assignedtoGroupVisibility){
                if (this.updateAllocationGroupField == '' || this.updateAllocationGroupField == null || this.updateAllocationGroupField == undefined) {
                    this.updateUnitAlertLabelValue = 'Please fill missing fields.';
                }else{
                    try{
                        await updateUnit({allocationGroup:this.updateAllocationGroupField, assignedTo:'null', propertyStatus:'', blockedReason:this.blockedReasonField , idList:this.rowsTableData, comments:this.blockedCommentsField, blockedBy:this.blockedByField, blockedDate:'null'})
                        const evt = new ShowToastEvent({
                            title: 'Unit Assignment',
                            message: 'Unit/s assigned successfully ',
                            variant: 'success',
                        });
                        this.dispatchEvent(evt);
                    }
                    catch(e){
                        const evt = new ShowToastEvent({
                            title: 'Unit Assignment',
                            message: 'Unit/s assignment failed ' + JSON.stringify(e),
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                    }
                    this.updateUnitModal = false;
                    this.updateUnitAlertLabelValue = '';
                    this.assignedtoGroupVisibility = false;
                    this.assignedtoUserVisibility = false;
                    // this.resetAll();
                    this.handleSearchAll();
                }
            } else if (this.updateAssignedToUserField == '' || this.updateAssignedToUserField == 'null' || this.updateAssignedToUserField == undefined) {
                this.updateUnitAlertLabelValue = 'Please fill missing fields.';
                }else {
                    try{
                        await updateUnit({allocationGroup:'null', assignedTo:this.updateAssignedToUserField, propertyStatus:'', blockedReason:this.blockedReasonField , idList:this.rowsTableData, comments:this.blockedCommentsField, blockedBy:this.blockedByField, blockedDate:'null'})
                        const evt = new ShowToastEvent({
                            title: 'Unit Assignment',
                            message: 'Unit/s assigned successfully ',
                            variant: 'success',
                        });
                        this.dispatchEvent(evt);
                    }
                    catch(e){
                        const evt = new ShowToastEvent({
                            title: 'Unit Assignment',
                            message: 'Unit/s assignment failed ' + JSON.stringify(e),
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                    }
                    this.updateUnitModal = false;
                    this.updateUnitAlertLabelValue = '';
                    this.assignedtoGroupVisibility = false;
                    this.assignedtoUserVisibility = false;
                    // this.resetAll();
                    this.handleSearchAll();
                }
        } else if (this.updatePropertyStatusField == 'Blocked') {
            this.updateUnitAlertLabelValue = '';
            this.blockFieldsVisibility = true;
            if (this.blockedCommentsField == '' || this.blockedCommentsField == null || this.blockedCommentsField == undefined || 
                this.blockedByField == '' || this.blockedByField == null || this.blockedByField == undefined  || 
                this.blockedReasonField == '' || this.blockedReasonField == null || this.blockedReasonField == undefined ) {
                    this.updateUnitAlertLabelValue = 'Please fill missing fields to block the unit.';
            }else {
                try{
                    await updateUnit({allocationGroup:this.updateAllocationGroupField, assignedTo:this.updateAssignedToUserField, propertyStatus:this.updatePropertyStatusField, blockedReason:this.blockedReasonField , idList:this.rowsTableData, comments:this.blockedCommentsField, blockedBy:this.blockedByField, blockedDate:'currentDate'})
                    const evt = new ShowToastEvent({
                        title: 'Unit Status',
                        message: 'Unit/s status updated successfully ',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                }
                catch(e){
                    const evt = new ShowToastEvent({
                        title: 'Unit Status',
                        message: 'Unit/s status updated failed ' + JSON.stringify(e),
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }
                this.updateUnitModal = false;
                this.updateUnitAlertLabelValue = '';
                this.blockedReasonField = '';
                this.blockedCommentsField = '';
                this.blockedByField = '';
                // this.resetAll();
                this.updatePropertyStatusField = ''
                this.handleSearchAll();
            }
        }else if (this.updatePropertyStatusField == 'Available'){
            this.blockedReasonField = ' ';
            this.blockedCommentsField = ' ';
            this.blockedByField = 'null';
            this.blockFieldsVisibility = false;
            
            try{
                await updateUnit({allocationGroup:this.updateAllocationGroupField, assignedTo:this.updateAssignedToUserField, propertyStatus:'Available', blockedReason:this.blockedReasonField , idList:this.rowsTableData, comments:this.blockedCommentsField, blockedBy:this.blockedByField, blockedDate:'null'})
                const evt = new ShowToastEvent({
                    title: 'Unit Status',
                    message: 'Unit/s status updated successfully ',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            }
            catch(e){
                const evt = new ShowToastEvent({
                    title: 'Unit Status',
                    message: 'Unit/s status updated failed ' + JSON.stringify(e),
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }
            
            this.updateUnitModal = false;
            this.updateUnitAlertLabelValue = '';
            // this.resetAll();
            this.updatePropertyStatusField = ''

            this.handleSearchAll();
        }else {
            this.blockFieldsVisibility = false;
            this.updateUnitAlertLabelValue = 'Please select Property Status.';
        }
        this.updateAllocationGroupField = '';
        this.updateAssignedToUserField = '';
        //this.propertyStatusField = '';
        
        this.selectedDatatableRows = [];
        this.updatePropertyButtonVisibility = false;
        this.assignmentActionsButtonVisibility = false;
        // this.assignedtoGroupVisibility = false;
        // this.assignedtoUserVisibility = false;
        this.isLoading=false;
    }
}