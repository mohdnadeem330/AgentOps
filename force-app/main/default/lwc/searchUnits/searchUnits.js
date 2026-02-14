import { api, LightningElement, track,wire } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
//TODO Delete
// import getUnitQuery from "@salesforce/apex/UnitService.getAllProjectsBrokerPortal";
//TODO Delete
// import prepareDropdownDataBrokerPortal from "@salesforce/apex/UnitService.getAllProjectsBrokerPortal";
// import prepareLocationNames from "@salesforce/apex/BuildingSectionService.prepareLocationNames";
// introducing resale based project filter through apex
// import populateProjects from "@salesforce/apex/UnitServiceWithoutSharing.getAllProjectsBrokerPortal";
import populateProjects from "@salesforce/apex/UnitServiceWithoutSharing.getAllProjectsBrokerPortalBySaleType";
import getUnits from "@salesforce/apex/UnitServiceWithoutSharing.getAllUnitsBrokerPortal";
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; // Added by Moh Sarfaraj for BPM-529


export default class SearchUnits extends LightningElement {
    fillter = resourcesPath + '/ALDARResources/svg/fillter.svg';
    //for Pagination 2 lines 
    currentPage = 1;
    pageSize = 10;
    //Filter js Start Here//
    buttonClicked;
    @track cssClass = 'filters-items';
    @track iconClass = 'filters-title';
    @track iconName = '';
    handleToggleClick() {
        this.buttonClicked = !this.buttonClicked;
        this.iconClass = this.buttonClicked ? 'filters-title addbg' : 'filters-title';
        this.cssClass = this.buttonClicked ? 'filters-items showfillter' : 'filters-items';
        this.iconName = this.buttonClicked ? 'utility:check' : '';
    }
    //Filter js End Here// 


    isLoading=true;
    projectList;
    selectedProject;
    showAdvancedFilter=false;
    unitData;
    tableData;
    unitTypePickListValues = [];
    unitModelPickListValues = [];
    communityPickListValues = [];
    unitCityPickListValues = [];
    buildingsPickListValues = [];
    projectNameList = [];
    saleTypePicklistValues = [{label: 'New Sale', value: 'New Sale'}, {label: 'Resale', value: 'Resale'}];

    priceRangeFrom=0;
    priceRangeTo;
    areaRangeFrom=0;
    areaRangeTo;
    shownodata= false;
    // Harsh@Aldar
    @track saleTypeField = 'New Sale';
    get isResale() {
        return this.saleTypeField === 'Resale';
    }
    
    connectedCallback(){
        //console.log('connectedCallback 1');
        //this.populateProjects();
    }
    currentPageReference = null;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log(currentPageReference)
        this.selectedProject='';
       if (currentPageReference && currentPageReference.state && currentPageReference.state.projectId) {
          this.selectedProject = currentPageReference.state.projectId;
          
       }
       this.populateProjects();
    }

    handleUnitSaleTypeChange(event){
        this.isLoading=true;
        this.saleTypeField = event.target.value;
        this.projectList = undefined;
        this.selectedProject='';
        this.currentPage = 1;
        // this.fetchUnits();
        this.populateProjects();
    }

    populateProjects(){
        const isResale = (this.saleTypeField && this.saleTypeField === 'Resale') ? true : false;
        populateProjects({isResale :isResale})
        .then(data => {
            //console.log('Populate project 2');
            //console.log(data);
            this.projectList = data;
            
            if(!this.selectedProject && data.length > 1){
                this.selectedProject = data[0].value;
            }
            if(this.selectedProject || this.selectedProject==''){
                this.fetchUnits();
            }else{
                this.isLoading=false;
            }
        })
        .catch(error => {
            //console.log(error)
            this.projectList = undefined;
            this.isLoading=false;
        });
    }
    handleProjectChange(event){
        this.isLoading=true;
        this.currentPage = 1;
        //console.log('handleProjectChange');
        this.selectedProject=event.detail.value;
        this.fetchUnits();
    }
    fetchUnits(){
        //console.log('Populate fetchUnits 3');
        //console.log(this.selectedProject);
        this.unitData = undefined;
        const isResale = this.saleTypeField && this.saleTypeField === 'Resale' ? true : false;
        getUnits({projectId :this.selectedProject, isResale :isResale})
        .then(data => {
            if (data && data.length > 0) {
                this.unitData = data;
            }else{
                this.unitData = undefined;
                this.isLoading=false;
            }
            this.initFilters();
        })
        .catch(error => {
            this.unitData = undefined;
            this.isLoading=false;
        });
    }
    resetFilters(){
        this.isLoading=true;
        this.priceRangeFrom=0;
        this.priceRangeTo=undefined;
        this.areaRangeFrom=0;
        this.areaRangeTo=undefined;
        this.selectedProject='';
        //console.log('resetFilters resetFilters');
        let allSearchFields = this.template.querySelectorAll('.unitFilters');
        for(let j = 0; j < allSearchFields.length; j++) {
            allSearchFields[j].value='';
        }

        this.fetchUnits();
       
    }
    initFilters(){
        //console.log('initFilters initFilters');
        //TODO filter arrays
        this.tableData=undefined;
        
        this.unitTypePickListValues = [];
        this.unitTypePickListValues.push({ label: 'Property Details', value: '' });
        this.unitModelPickListValues = [];
        this.unitModelPickListValues.push({ label: 'All', value: '' });
        this.communityPickListValues = [];
        this.communityPickListValues.push({ label: 'All', value: '' });
        this.unitCityPickListValues = [];
        this.unitCityPickListValues.push({ label: 'All', value: '' });
        this.buildingsPickListValues = [];
        this.buildingsPickListValues.push({ label: 'All', value: '' });
        this.projectNameList = [];
        this.projectNameList.push({ label: 'All Projects', value: '' })
        if(this.unitData){
            this.tableData=[];
            let allSearchFields = this.template.querySelectorAll('.unitFilters');
            
            for(let i=0; i<this.unitData.length ;i++){
                //console.log('----'+i+'----');
                var recordFiltered=false;
                for(let j = 0; j < allSearchFields.length; j++) {
                    if(allSearchFields[j].value!=undefined && allSearchFields[j].value!='' ){
                        if(allSearchFields[j].dataset.field =='Name'){
                            if((this.unitData[i][allSearchFields[j].dataset.field].toLowerCase().search(allSearchFields[j].value.toLowerCase()) == -1 )){
                                recordFiltered=true;
                                break;
                            }
                        }else if(allSearchFields[j].dataset.field =='City__c'){
                            if(this.unitData[i].Project__r.City__c != allSearchFields[j].value){
                                recordFiltered=true;
                                break;
                            }
                        }else if(allSearchFields[j].dataset.field =='BuildingSectionName__c'  ){
                            if(this.unitData[i].BuildingSectionName__r.Name != allSearchFields[j].value){
                                recordFiltered=true;
                                break;
                            }
                        }else if(this.unitData[i][allSearchFields[j].dataset.field] != allSearchFields[j].value){
                            recordFiltered=true;
                            break;
                        }
                    }
                }
                //console.log('----'+i+'----');
                if((this.priceRangeFrom &&  (!this.unitData[i].SellingPrice__c || this.unitData[i].SellingPrice__c < this.priceRangeFrom) ) || (this.priceRangeTo &&  (!this.unitData[i].SellingPrice__c || this.unitData[i].SellingPrice__c > this.priceRangeTo) )){
                    recordFiltered=true;
                }
                
                
                if((this.areaRangeFrom && ( !this.unitData[i].TotalArea__c || this.unitData[i].TotalArea__c < this.areaRangeFrom )) || (this.areaRangeTo &&  (!this.unitData[i].TotalArea__c  || this.unitData[i].TotalArea__c > this.areaRangeTo) )){
                    recordFiltered=true;
                }
                //console.log('--1--'+i+'----');
                if(!recordFiltered){
                    //add picklist data
                    //console.log('--2--'+i+'----');
                    if(this.unitData[i].UnitType__c && this.unitData[i].UnitType__c!='' && this.unitTypePickListValues.findIndex((item) => item.label === this.unitData[i].UnitType__c) === -1 ){
                        this.unitTypePickListValues.push({ label: this.unitData[i].UnitType__c, value: this.unitData[i].UnitType__c });
                    }
                    //console.log('---3-'+i+'----');
                    if(this.unitData[i].UnitModel__c && this.unitData[i].UnitModel__c!='' && this.unitModelPickListValues.findIndex((item) => item.label === this.unitData[i].UnitModel__c) === -1 ){
                        this.unitModelPickListValues.push({ label: this.unitData[i].UnitModel__c, value: this.unitData[i].UnitModel__c });
                    }
                    //console.log('--4--'+i+'----');
                    if(this.unitData[i].CommunityName__c && this.unitData[i].CommunityName__c!='' && this.communityPickListValues.findIndex((item) => item.label === this.unitData[i].CommunityName__c) === -1 ){
                        this.communityPickListValues.push({ label: this.unitData[i].CommunityName__c, value: this.unitData[i].CommunityName__c });
                    }
                    //console.log('---6-'+i+'----');
                    if(this.unitData[i].Project__c && this.unitData[i].Project__r.City__c && this.unitData[i].Project__r.City__c!='' && this.unitCityPickListValues.findIndex((item) => item.label === this.unitData[i].Project__r.City__c) === -1 ){
                        this.unitCityPickListValues.push({ label: this.unitData[i].Project__r.City__c, value: this.unitData[i].Project__r.City__c });
                    }
                    //console.log('---9-'+i+'----');
                    if(this.unitData[i].BuildingSectionName__c && this.unitData[i].BuildingSectionName__r.Name && this.unitData[i].BuildingSectionName__r.Name!='' && this.buildingsPickListValues.findIndex((item) => item.label === this.unitData[i].BuildingSectionName__r.Name) === -1 ){
                        this.buildingsPickListValues.push({ label: this.unitData[i].BuildingSectionName__r.Name, value: this.unitData[i].BuildingSectionName__r.Name });
                    }
                    //console.log('----iiii----');
                    this.tableData.push(this.unitData[i]);
                }
            }
        }
        if(this.tableData.length ==0){
            this.shownodata= true;
        }
        this.isLoading=false;
    }

//@track data;
@track sortBy;
@track sortDirection;

isExport=false;
doneTypingInterval = 0;





//projectNamePickListValues = [];
@track selectedRows;

filterIcon=resourcesPath+ "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon=resourcesPath +"/ALDARResources/svg/ResetIcon.svg";
listIcon = resourcesPath + "/ALDARResources/svg/ListIcon.svg";;
exportIcon = resourcesPath + "/ALDARResources/svg/ExportIcon.svg";
generateOffers= resourcesPath + "/ALDARResources/svg/GenerateOffers.svg";
compareUnits= resourcesPath + "/ALDARResources/svg/CompareUnits.svg";
priceRange= resourcesPath + "/ALDARResources/svg/Price.svg";
areaIcon= resourcesPath + "/ALDARResources/svg/AreaIcon.svg";
defaultSortDirection = 'asc';
    sortDirection = 'asc';

    @api showCompareUnits=false;
    @api showUnitsDetailsPage=false;

    neededDataForReserveFlow;
    @track showSpinner=false;


tableColumns=[
    {
        sortable: true,
        type: 'text',
        fieldName: 'CommunityName__c',
        label: 'Community',
        //initialWidth:95,
        cellAttributes: { class: 'community-cell' /*important for reponsive */ }
    },
    {sortable: true,
        type: 'text',
        fieldName: 'ProjectName__c',
        label: 'Property Name',
        //initialWidth:130,
        cellAttributes: { class: 'property-name-cell' /*important for reponsive */ }
    },
    {sortable: true,
        type: 'text',
        fieldName: 'Name',
        //initialWidth:150,
        label: 'End Unit Code',
        cellAttributes: { class: 'end-unit-code-cell' /*important for reponsive */ }
    },
    { 
    label: 'Actions',
    fieldName:  'view', 
    initialWidth: 90,
    type: 'button', 
    typeAttributes: { 
        iconName: 'action:preview',
    
    name: 'View', 
    title: 'View', 
    initialWidth:35,
    disabled: false, 
    value: 'Edit'
     
    },
    cellAttributes: {
        class:'custom-table-icon view-icon',
        alignment: 'center',
        iconPosition: 'center',
    }
    },
    /*{   
        
        fieldName:  'property', 
        initialWidth: 40,
        type: 'button', 
        typeAttributes: { 
            iconName: 'utility:edit',
        
        name: 'ReserveNow', 
        title: 'Reserve Now', 
        disabled: false, 
        value: 'Edit'
         
        },
        cellAttributes: {
            class:'custom-table-icon reserve-now-icon',
            alignment: `left`
        }
    },*/
    {
        sortable: true,
            label: 'Status',
            //initialWidth: 120,
            fieldName: 'Status__c',
            type: 'text',
            cellAttributes: {
                iconName: { fieldName: 'statusIcon' },
                iconPosition: 'left',
                class: 'status-cell' /*important for reponsive */
            }
        
             
    },
    {sortable: true,
        type: 'text',
        fieldName: 'UnitType__c',
        label: 'Unit Type',
        //initialWidth:110,
        cellAttributes: { class: 'unit-type-cell' /*important for reponsive */ }
    },
    {sortable: true,
        type: 'text',
        fieldName: 'UnitModel__c',
        label: 'Unit Model',
        //initialWidth:120,
        cellAttributes: { class: 'unit-model-cell' /*important for reponsive */ }
    },
    {sortable: true,
        type: 'text',
        fieldName: 'UnitView__c',
        label: 'Unit View',
        //initialWidth:120,
        cellAttributes: { class: 'unit-view-cell' /*important for reponsive */ }
    },
    {sortable: true,
        type: 'number',
        typeAttributes: {
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
        },
        fieldName: 'UnitPlotArea__c',
        label: 'Plot Area',
        //initialWidth:120,
        cellAttributes: { class: 'plot-area-cell' /*important for reponsive */ }
    },
    /*{sortable: true,
        type: 'number',
        typeAttributes: {
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
        },
        fieldName: 'MeasuredInternalArea__c',
        label: 'Internal Area',
        initialWidth:120,
        cellAttributes: { class: 'internal-area-cell' /*important for reponsive */ /*}
    },
    {sortable: true,
        type: 'number',
        typeAttributes: {
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
        },
        fieldName: 'TerraceArea__c',
        label: 'Terrace Area',
        initialWidth:120,
        cellAttributes: { class: 'terrace-area-cell' /*important for reponsive */ /*}
    }, 
    {sortable: true,
        type: 'number',
        typeAttributes: {
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
        },
        fieldName: 'TotalArea__c',
        label: 'Total Area',
        initialWidth:120,
        cellAttributes: { class: 'total-area-cell' /*important for reponsive */ /*}
    }, */
    {sortable: true,
        type: 'currency',  // updated By Moh Sarfaraj for BPE-324
        typeAttributes: {
            currencyCode: { fieldName: 'CurrencyIsoCode' },
            currencyDisplayAs: 'code'
        },
        fieldName: 'SellingPrice__c',
        label: 'Selling Price',
        //initialWidth:120,
        cellAttributes: { class: 'market-selling-price-cell' /*important for reponsive */ }
    }
    
];
tableColumns_Resale = [
    {
        sortable: true,
        type: 'text',
        fieldName: 'CommunityName__c',
        label: 'Community',
        //initialWidth:95,
        cellAttributes: { class: 'community-cell' /*important for reponsive */ }
    },
    {
        sortable: true,
        type: 'text',
        fieldName: 'ProjectName__c',
        label: 'Property Name',
        //initialWidth:130,
        cellAttributes: { class: 'property-name-cell' /*important for reponsive */ }
    },
    {
        sortable: true,
        type: 'text',
        fieldName: 'PropertyId__c',
        //initialWidth: 150,
        label: 'Property Code',
        cellAttributes: { class: 'end-unit-code-cell' /*important for reponsive */ }
    },
    {
        label: 'Actions',
        fieldName: 'view',
        initialWidth: 90,
        type: 'button',
        typeAttributes: {
            iconName: 'utility:edit',
            name: 'View',
            title: 'View',
            initialWidth: 35,
            disabled: false,
            value: 'Edit'
        },
        cellAttributes: {
            class: 'custom-table-icon view-icon',
            alignment: 'center',
            iconPosition: 'center',
        }
    },
    // {
    //     sortable: true,
    //     label: 'Status',
    //     //initialWidth: 120,
    //     fieldName: 'Status__c',
    //     type: 'text',
    //     cellAttributes: {
    //         iconName: { fieldName: 'statusIcon' },
    //         iconPosition: 'left',
    //         class: 'status-cell' /*important for reponsive */
    //     }
    // },
    {
        sortable: true,
        type: 'text',
        fieldName: 'UnitType__c',
        label: 'Unit Type',
        //initialWidth:110,
        cellAttributes: { class: 'unit-type-cell' /*important for reponsive */ }
    },
    {
        sortable: true,
        type: 'text',
        fieldName: 'UnitModel__c',
        label: 'Unit Model',
        //initialWidth:120,
        cellAttributes: { class: 'unit-model-cell' /*important for reponsive */ }
    },
    {
        sortable: true,
        type: 'text',
        fieldName: 'UnitView__c',
        label: 'Unit View',
        //initialWidth:120,
        cellAttributes: { class: 'unit-view-cell' /*important for reponsive */ }
    },
    {
        sortable: true,
        type: 'number',
        typeAttributes: {
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
        },
        fieldName: 'UnitPlotArea__c',
        label: 'Plot Area',
        //initialWidth:120,
        cellAttributes: { class: 'plot-area-cell' /*important for reponsive */ }
    },
    {
        sortable: true,
        type: 'currency', // updated By Moh Sarfaraj for BPE-324
        typeAttributes: {
            currencyCode: { fieldName: 'CurrencyIsoCode' },
            currencyDisplayAs: 'code'
        },
        fieldName: 'Listing_Price__c', // Use Listing Price for Resale
        label: 'Listing Price',
        //initialWidth:120,
        cellAttributes: { class: 'market-selling-price-cell' /*important for reponsive */ }
    },
];


/*
    async getDropDownData(){
        this.showSpinner=true;

        try {
            
        
        let projectNameData = [{ label: "None", value: null }];
        let unitTypeData = [{ label: "None", value: null }];
        let communityData = [{ label: "None", value: null }];
        let unitModelData = [{ label: "None", value: null }];
        let cityData = [{ label: "None", value: null }];

        let dropdownData = [];
        let newBuildingsNamesDataTableData = [{ label: "None", value: null }];
        let newBuildingsNamesData = [];
        

        if (this.projectNameField == '' || this.projectNameField == null || this.projectNameField == undefined ) {
            dropdownData = await prepareDropdownDataBrokerPortal();

            for (let i = 0; i < dropdownData.length; i++)
            {
                if (dropdownData[i].Project__r.Name) {
                    projectNameData.push({ label: dropdownData[i].Project__r.Name, value: dropdownData[i].Project__r.Name });
                    }
            }

            const filteredProjectNameData = projectNameData.reduce((acc, current) => {
                const x = acc.find(item => item.label === current.label);
                if (!x) {
                  return acc.concat([current]);
                } else {
                  return acc;
                }
            }, []);

            this.projectNamePickListValues = filteredProjectNameData;

        } else {
            dropdownData = await prepareDropdownDataBrokerPortal({projectNameParam :this.projectNameField});
            ////console.log('dropdownData ' +JSON.stringify(dropdownData));

            newBuildingsNamesData = await prepareLocationNames({projectName :this.projectNameField}) ;
            for (let i = 0; i < newBuildingsNamesData.length; i++)
            {
                newBuildingsNamesDataTableData.push({ label: newBuildingsNamesData[i].Name, value: newBuildingsNamesData[i].Id });
            }
        }
        

        for (let i = 0; i < dropdownData.length; i++)
        {
            if (dropdownData[i].UnitType__c) {
                unitTypeData.push({ label: dropdownData[i].UnitType__c + '', value: dropdownData[i].UnitType__c+ '' });
            }
            if (dropdownData[i].CommunityName__c) {
                communityData.push({ label: dropdownData[i].CommunityName__c, value: dropdownData[i].CommunityName__c });
            }
            if (dropdownData[i].UnitModel__c) {
                unitModelData.push({ label: dropdownData[i].UnitModel__c, value: dropdownData[i].UnitModel__c });
            }
            if (dropdownData[i].Project__r.City__c) {
                cityData.push({ label: dropdownData[i].Project__r.City__c, value: dropdownData[i].Project__r.City__c });
            }
        }

        const filteredUnitTypeData = unitTypeData.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);

        const filteredCommunityData= communityData.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);

        const filteredUnitModelData= unitModelData.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);

        const filteredCityData= cityData.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);

        this.buildingsPickListValues = newBuildingsNamesDataTableData;
        this.unitTypePickListValues = filteredUnitTypeData;
        this.communityPickListValues = filteredCommunityData;
        this.unitModelPickListValues = filteredUnitModelData;
        this.unitCityPickListValues = filteredCityData;


        this.showSpinner=false;

    } catch (error) {
         
        this.showSpinner=false;
    }
    }*/
/*
    async resetAll() {
        try {
            this.showSpinner=true;
        //console.log('resetall');

        let newTableData = [];
        let query;

        query = 'SELECT Id,CommunityName__c,Project__r.Name,Name,Status__c,UnitType__c,UnitModel__c,UnitView__c,PlotArea__c,UnitPlotArea__c, MeasuredInternalArea__c,TerraceArea__c,TotalArea__c,MarketPrice__c,SellingPrice__c FROM Unit__c WHERE OnlineBrokerFlag__c = True';
        const newData = await getUnitQuery({query:query});
        newData.forEach(record => {
            record.ProjectName__c = record.Project__r.Name;
        });

        for (let i = 0; i < newData.length; i++) {
            newTableData.push(newData[i]);
        }
        this.data = newTableData;

        this.getDropDownData();

        this.buildingNameField = '';
        this.projectNameField = '';
        this.unitCodeField = '';
        this.unitTypeField = '';
        this.unitModelField = '';
        this.unitCityField = '';
        this.communityField = '';

        this.showSpinner=false;
    } catch (error) {
        this.showSpinner=false;
    }
    }*/

    exportToCSV() { 
     
        let columnHeader = ["Community","Property Name", "End Unit Code", "Unit Type", "Status", "Unit Model", "Unit View", "Plot Area", "Internal Area", "Terrace Area", "Total Area", "Market Selling Price"];  // This array holds the Column headers to be displayd

        let jsonKeys = ["community","ProjectName__c","endUnitCode","Status__c","UnitType__c","UnitModel__c","UnitView__c","UnitPlotArea__c","MeasuredInternalArea__c","TerraceArea__c","TotalArea__c","SellingPrice__c"]; // This array holds the keys in the json data  
        var jsonRecordsData = this.selectedRows;  
        let csvIterativeData;  
        let csvSeperator ; 
        let newLineCharacter;  
        csvSeperator = ",";  
        newLineCharacter = "\n";  
        csvIterativeData = "";  
        csvIterativeData += columnHeader.join(csvSeperator);  
        csvIterativeData += newLineCharacter;  
        for (let i = 0; i < jsonRecordsData.length; i++) {  
          let counter = 0;  
          for (let iteratorObj in jsonKeys) {  
            let dataKey = jsonKeys[iteratorObj];  
            if (counter > 0) {  csvIterativeData += csvSeperator;  }  
            if (  jsonRecordsData[i][dataKey] !== null &&  
              jsonRecordsData[i][dataKey] !== undefined  
            ) {  csvIterativeData += '"' + jsonRecordsData[i][dataKey] + '"';  
            } else {  csvIterativeData += '""';  
            }  
            counter++;  
          }  
          csvIterativeData += newLineCharacter;  
        }  
        this.hrefdata = "data:text/csv;charset=utf-8," + encodeURI(csvIterativeData);  
        csvIterativeData = csvIterativeData.replace(/"/g, '');

        var downloadLink = document.createElement("a"); 
        document.body.appendChild(downloadLink);
        downloadLink.href = 'data:application/vnd.ms-excel,'+csvIterativeData;
        downloadLink.download = 'Units.xls.csv';
        downloadLink.click();
      }  
    /*
    async handleSearchAll(event) {
        
        let newTableData = [];
    
        
        var condition = (this.buildingNameField !== '' && this.buildingNameField !== null && this.buildingNameField !== undefined
          ? 'BuildingSectionName__c =\'' + this.buildingNameField +'\'': '');

          condition += (this.projectNameField !== '' && this.projectNameField !== null && this.projectNameField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
          ' Project__r.Name LIKE \'' +
            '%' +
            this.projectNameField +
            '%\''
          : '');

          condition += (this.unitCodeField !== '' && this.unitCodeField !== null && this.unitCodeField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            ' Name LIKE \'' +
            '%' +
            this.unitCodeField +
            '%\''
          : '');

          condition += (this.unitTypeField !== '' && this.unitTypeField !== null && this.unitTypeField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
          'UnitType__c =\'' + this.unitTypeField +'\'': ''); 

          condition += (this.unitModelField !== '' && this.unitModelField !== null && this.unitModelField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
          'UnitModel__c =\'' + this.unitModelField +'\'': '');

          condition += (this.unitCityField !== '' && this.unitCityField !== null && this.unitCityField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
          'Project__r.City__c =\'' + this.unitCityField +'\'': '');

          condition += (this.priceRangeFrom !== '' && this.priceRangeFrom !== null && this.priceRangeFrom !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
          'SellingPrice__c  >=' + this.priceRangeFrom : '');

          condition += (this.priceRangeTo !== '' && this.priceRangeTo !== null && this.priceRangeTo !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
          'SellingPrice__c  <=' + this.priceRangeTo: '');

          condition += (this.areaRangeFrom !== '' && this.areaRangeFrom !== null && this.areaRangeFrom !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
          'TotalArea__c   >=' + this.areaRangeFrom : '');

          condition += (this.areaRangeTo !== '' && this.areaRangeTo !== null && this.areaRangeTo !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
          'TotalArea__c   <=' + this.areaRangeTo : '');

          condition += (this.communityField !== '' && this.communityField !== null && this.communityField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            'CommunityName__c  =\'' + this.communityField +'\'': '');

          condition += (condition !== '' && condition !== null ? ' AND ' : '') + 'OnlineBrokerFlag__c = True';
            
          var query;
          if (condition !== '' && condition !== null && condition !== undefined ) {
            query = 'SELECT Id,CommunityName__c,Project__r.Name,Name,Status__c,UnitType__c,UnitModel__c,UnitView__c,PlotArea__c,UnitPlotArea__c, MeasuredInternalArea__c,TerraceArea__c,TotalArea__c,MarketPrice__c,SellingPrice__c FROM Unit__c WHERE ' +
            condition;
          }else{
            query = 'SELECT Id,CommunityName__c,Project__r.Name,Name,Status__c,UnitType__c,UnitModel__c,UnitView__c,PlotArea__c,UnitPlotArea__c, MeasuredInternalArea__c,TerraceArea__c,TotalArea__c,MarketPrice__c,SellingPrice__c FROM Unit__c WHERE OnlineBrokerFlag__c = True';
          }
          //console.log('condition' + condition + 'condition');

          //console.log(query);

        const newData = await getUnitQuery({query:query});

        newData.forEach(record => {
            record.ProjectName__c = record.Project__r.Name;
        });

        for (let i = 0; i < newData.length; i++) {
            newTableData.push(newData[i]);
        }
        //console.log(newTableData);

        this.data = newTableData;
        
    }*/

  
    /*
    handleKeyUp(event) {
        clearTimeout(this.typingTimer);
        let value = event.target.value;
        let name = event.target.name;

        this.typingTimer = setTimeout(() => {
            this[name] = value;
        }, this.doneTypingInterval);
        ////console.log('unitCodeField ' +this.unitCodeField);
        
    }*/

    /*async handleProjectChange(event) {
        this[event.target.name] = event.target.value;
        this.getDropDownData();
    }*/

    showHideFilters(){
        this.showAdvancedFilter=!this.showAdvancedFilter;
    }

    transferDataToAnotherComponent(){
        // Added by Moh Sarfaraj for BPM-529 starts
        if(this.disableGenerateOffer == true){
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Cannot generate offers for LSQ Projects.',
                variant : 'error'
            });
            this.dispatchEvent(event);
            return;
        }
        // Added by Moh Sarfaraj for BPM-529 end

        const transferDataEvent= new CustomEvent('transferdata', {
           
            detail: {selected:this.selectedRows }
        });
        this.dispatchEvent(transferDataEvent);
    }

generateOfferFromUnitDetails(event){
    const transferDataEvent= new CustomEvent('transferdata', {
           
        detail: {selected:event.detail.selected }
    });
this.dispatchEvent(transferDataEvent);
}

    clickedRow(event){
let row=event.detail.row;
let clickedIcon=event.detail.action.name;

if(clickedIcon == "View"){
    

    this.selectedRows=[event.detail.row].map((item)=>{
           
        return { Id:item.Id
            ,community:item.CommunityName__c
            ,endUnitCode:item.Name
            ,ProjectName__c:item.Project__r.Name
            ,Project__c:item.Project__c
            ,Status__c:item.Status__c
            ,UnitType__c:item.UnitType__c
            ,UnitModel__c:item.UnitModel__c
            ,UnitView__c:item.UnitView__c
            ,UnitPlotArea__c:item.UnitPlotArea__c
            ,MeasuredInternalArea__c:item.MeasuredInternalArea__c
            ,TerraceArea__c:item.TerraceArea__c
            ,TotalArea__c:item.TotalArea__c
            ,SellingPrice__c:item.SellingPrice__c
            ,Listing_Price__c: item.Listing_Price__c
            ,propertyCode: item.PropertyId__c
            ,isResale: this.isResale
        }
    
    });

    // //console.log(">>>>>>>>>>>@@@@@@@@@");
    // //console.log(this.selectedRows);
    // //console.log(">>>>>>>>>>>@@@@@@@@@");

this.showUnitsDetailsPage=true;
document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {showNavigationTab:false,currentStep:"unitDetails" }}));


}else if(clickedIcon == "ReserveNow"){
        let neededData=[];
        neededData.push({Id:row.Id,name:row.Name});
        
        this.neededDataForReserveFlow=neededData;

        this.reserveNow(neededData);
        }
            }
        
        
            reserveNow(neededData){
        
            
        this.dispatchEvent(new CustomEvent('reservenow', {detail: neededData }));
        
        
        }

        reserveNowForMultipleSelection(){
            this.reserveNow(this.neededDataForReserveFlow);
        }


    disableGenerateOffer = false;

    getSelected(event){

        this.selectedRows=event.detail.selectedRows.map((item)=>{
           
            return { Id:item.Id
                ,community:item.CommunityName__c
                ,endUnitCode:item.Name
                ,ProjectName__c:item.Project__r.Name
                ,Project__c:item.Project__c
                ,Status__c:item.Status__c
                ,UnitType__c:item.UnitType__c
                ,UnitModel__c:item.UnitModel__c
                ,UnitView__c:item.UnitView__c
                ,UnitPlotArea__c:item.UnitPlotArea__c
                ,MeasuredInternalArea__c:item.MeasuredInternalArea__c
                ,TerraceArea__c:item.TerraceArea__c
                ,TotalArea__c:item.TotalArea__c
                ,SellingPrice__c:item.SellingPrice__c
                ,Country__c : item.Project__r.Country__c != null ? item.Project__r.Country__c : ''  // Added by Moh Sarfaraj for BPM-529

            }
        
        });

        this.neededDataForReserveFlow=event.detail.selectedRows.map((item)=>{
            return { Id:item.Id,
                name:item.Name
            }
        });

        // Added by Moh Sarfaraj for BPM-529 start
        this.disableGenerateOffer = false;
        if(this.selectedRows.length > 0){
            for(let i in this.selectedRows){
                if(this.selectedRows[i].Country__c === 'United Kingdom'){
                    this.disableGenerateOffer = true;
                    break;
                }
            }
        }
        // Added by Moh Sarfaraj for BPM-529 end

        let selectedRows = event.detail.selectedRows;
        if(selectedRows.length) {
            this.template.querySelector(".buttons-above-table-container").classList.add("active");
        }else{
            this.template.querySelector(".buttons-above-table-container").classList.remove("active");
        }


    }

    get getStyle(){

       return (this.selectedRows?.length <1 || this.selectedRows == undefined )   ?"pointer-events: none;opacity:0.5;":"pointer-events: unset;opacity:1;";
        
    }

    getAreaRangeFilter(event){
        //console.log(JSON.stringify(event.detail));
        this.areaRangeFrom = event.detail.start;
        this.areaRangeTo = event.detail.end;
    }

    getPriceRangeFilter(event){
        console.log(JSON.stringify(event.detail));
        this.priceRangeFrom = event.detail.start;
        this.priceRangeTo = event.detail.end;
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
        let parseData = JSON.parse(JSON.stringify(this.unitData));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
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
        this.unitData = parseData;
        this.initFilters();

    }


    handleCompareUnits(){

        if(this.selectedRows.length <2){
         alert("Please selected another Units to compare.");
        }else if(this.selectedRows.length >3){
            alert("Maximum units number to compare is 3.");
        }else{
            this.showCompareUnits=true;
            document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {showNavigationTab:false,currentStep:"compareUnits" }}));
        }
    }

    closeCompareUnits(event){
        this.showCompareUnits= event.detail.isOpen;
    }

    handleCloseUnitsDetailsPage(event){
    this.showUnitsDetailsPage=false;
    }

    get showMainPage(){
 
        if(this.showCompareUnits || this.showUnitsDetailsPage){
           return false;
        }else{
            return true;     
        } 
    }

    // Pagination : Show Pagination if available
    get showPagination(){
        return this.totalPages > 0;
    }

    // Pagination : Calculate the total number of pages
    get totalPages() {
        if (this.tableData != undefined) {
            return Math.ceil(this.tableData.length / this.pageSize);
        } else {
            return 0;
        }
    }

    // Pagination : Handle "Previous" button click
    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    // Pagination : Handle "Next" button click
    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }

     // Pagination and global search filter 
    @track generalFilter = '';

get currentData() {
    const startIndex = (this.currentPage - 1) * this.pageSize;
    const endIndex = startIndex + this.pageSize;
    const filterValue = this.generalFilter.toLowerCase();
    const minPrice = parseFloat(this.priceRangeFrom); // Convert to float
    const maxPrice = parseFloat(this.priceRangeTo);

 

    if (!this.tableData) {
        return [];
    }

 

    const filteredData = this.tableData.filter(record => {
        // Check if any value in the record matches the general filter
        const generalFilterMatch = Object.values(record).some(value => {
            if (value && typeof value === 'string') {
                return value.toLowerCase().includes(filterValue);
            }
            return false;
        });

 

        // Check if minPrice and maxPrice are valid numbers, and apply the price range filter
        if (!isNaN(minPrice) && !isNaN(maxPrice)) {
            const price = parseFloat(record.SellingPrice__c);
            return generalFilterMatch && price >= minPrice && price <= maxPrice;
        } else {
            // If either minPrice or maxPrice is not a valid number, only apply the general filter
            return generalFilterMatch;
        }
    });

 

    return filteredData.slice(startIndex, endIndex);
}


    handleFilterChange(event) {
        this.generalFilter = event.target.value;


    }


}