import { api, LightningElement, track, wire } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import {
    EXAMPLES_COLUMNS_DEFINITION_BASIC,
    EXAMPLES_DATA_BASIC,
} from './sampleData';
import Id from '@salesforce/user/Id';
import getMapDetails from '@salesforce/apex/BrokerLeadController.getMapDetails';
import getsobjectName from '@salesforce/apex/BrokerLeadController.getsobjectName';
import getUserDetails from '@salesforce/apex/BrokerLeadController.getUserDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Project_FIELD from '@salesforce/schema/Lead.Project__c';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import Country_FIELD from '@salesforce/schema/Lead.Nationality__c';

export default class LeadSelection extends LightningElement {

    @track gridColumns = EXAMPLES_COLUMNS_DEFINITION_BASIC;

    // data provided to the tree grid
    @track gridData = [];
    @track gridData1 = EXAMPLES_DATA_BASIC;
    @api gridExpandedRows = [];
    arr = [];
    toExpandRow = [];


    addLeadIcon = resourcesPath + "/ALDARResources/svg/ListIcon.svg";
    @api selectedRows = [];
    @api fromSearchUnit;

    userId = Id;
    @track newData = false;
    allResult;
    sObjectName;
    @track isModalOpen = false;
    oldChildsSelected = [];
    selectedChildCurrently;
    selectedItemToTransfer;
    selectedChildToTransfer;
    @api canProceed = false;
    @track showSpinner = false;
    @track filteredData = [];

 //Filter js Start Here// 
    fillter = resourcesPath + '/ALDARResources/svg/fillter.svg';
    buttonClicked;
    @track cssClass = 'filters-items newfillter';
    @track iconClass = 'filters-title';
    @track iconName = '';
    handleToggleClick() {
        this.buttonClicked = !this.buttonClicked;
        this.iconClass = this.buttonClicked ? 'filters-title addbg' : 'filters-title';
        this.cssClass = this.buttonClicked ? 'filters-items newfillter showfillter' : 'filters-items newfillter';
        this.iconName = this.buttonClicked ? 'utility:check' : '';
    }
    //Filter js End Here//

    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";

    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    leadMetadata;

    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: Project_FIELD
        }
    )
    projectPicklist;

    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: Country_FIELD
        }
    )
    countryPicklist;

    getUserDetails() {
        getUserDetails({ userId: this.userId })
            .then(result => {
                console.log('getUserDetails : ' + JSON.stringify(result));

                this.contactUserId = result.ContactId;
                this.agencyName = result.Contact.Account.Name;

            })
            .catch(error => {
                console.log('getUserDetails error: ' + JSON.stringify(error));
            });
    }

    @track nameFilter = '';
    @track emailFilter = '';
    @track mobileFilter = '';
    @track agentFilter = '';
    @track countryFilter = '';
    @track projectFilter = '';
    @track dateFilter = '';

    handleChange(event) {

        var value = event.target.value;

        if (event.target.dataset.id === 'nameFilter') {
            this.nameFilter = value;
        } else if (event.target.dataset.id === 'emailFilter') {
            this.emailFilter = value;
        } else if (event.target.dataset.id === 'mobileFilter') {
            this.mobileFilter = value;
        } else if (event.target.dataset.id === 'agentFilter') {
            this.agentFilter = value;
        } else if (event.target.dataset.id === 'countryFilter') {
            this.countryFilter = value;
        } else if (event.target.dataset.id === 'projectFilter') {
            this.projectFilter = value;
        } else if (event.target.dataset.id === 'dateFilter') {
            this.dateFilter = value;
        }
    }

    resetAll() {
        this.filteredData = this.gridData;
        this.nameFilter = '';
        this.emailFilter = '';
        this.mobileFilter = '';
        this.agentFilter = '';
        this.countryFilter = '';
        this.projectFilter = '';
        this.dateFilter = '';
    }

    updateSearch(event) {

        this.filteredData = this.gridData;

        this.gridExpandedRows = [];
        this.arr = [];
        this.toExpandRow = []
        this.selectedRows = []

        var regex1 = new RegExp(this.nameFilter, 'i');
        var regex2 = new RegExp(this.emailFilter, 'i');
        var regex3 = new RegExp(this.mobileFilter, 'i');
        var regex4 = new RegExp(this.agentFilter, 'i');
        var regex5 = new RegExp(this.countryFilter, 'i');
        var regex6 = new RegExp(this.projectFilter, 'i');
        var regex7 = new RegExp(this.dateFilter, 'i');

        if (this.nameFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex1.test(row.column2) || regex1.test(row.column3) || regex1.test(row.column2 + ' ' + row.column3))
            );
        }
        if (this.emailFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex2.test(row.column4))
            );
        }
        if (this.mobileFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex3.test(row.column5))
            );
        }
        if (this.agentFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex4.test(row.agentName))
            );
        }
        if (this.countryFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex5.test(row.column6))
            );
        }
        if (this.projectFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex6.test(row.pjct))
            );
        }
        if (this.dateFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex7.test(row.createdDate))
            );
        }
    }
    
    async getData() {
        this.gridData = [];

        console.log('this.userId: ' + JSON.stringify(this.userId));





        await getMapDetails().then(result => {
            this.showSpinner = true;

            this.allResult = result;
            console.log('getMapDetails : ' + JSON.stringify(result));

            let count = 0;

            for (const i in result) {

                let objectname = null;

                getsobjectName({ recordID: result[i].column0 })
                    .then(data => {
                        objectname = data;

                        console.log('objectname: ' + JSON.stringify(objectname));

                        if (objectname['Lead'] != null) {
                            this.allResult[i].children.push(objectname['Lead']);
                        }

                        this.newData = true;

                    })
                    .catch(error => {
                        console.log('getsobjectName error: ' + JSON.stringify(error));
                        console.log(error);
                    });

                this.gridData.push({
                    //column0: result[i].column0,
                    column1: result[i].column1,
                    column2: result[i].column2,
                    column3: result[i].column3,
                    column4: result[i].column4,
                    column5: result[i].column5,
                    column6: result[i].column6,
                    column7: result[i].column0,
                    lastModifiedDate: result[i].lastModifiedDate,
                    createdDate: result[i].createdDate,
                    pjct: result[i].project,
                    agentName: result[i].agentName,
                    _children: []
                });

                setTimeout(() => {
                    for (let x = 0; x < result[i].children.length; x++) {

                        console.log('objectname: ' + JSON.stringify(objectname));

                        let d = new Date(result[i].children[x].CreatedDate);
                        let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(d);
                        let mo = new Intl.DateTimeFormat('en', { month: '2-digit' }).format(d);
                        let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(d);

                        try {
                            this.gridData[count]._children.push({
                                column1: 'Project: ' + result[i].children[x].Project__c,
                                column2: '',
                                column3: 'Unity Type: ' + result[i].children[x].UnitType__c,
                                column4: '',
                                column5: 'Created Date & Time: ' + new Date(result[i].children[x].CreatedDate).toLocaleString(),
                                column6: 'Agent Name: ' + result[i].children[x].BrokerAgent__r.Name,
                                column7: result[i].children[x].Id + '-child'+x,
                            });
                        } catch (e) {
                            console.log(e);
                        }

                        this.gridData[count].createdDate = this.gridData[count].createdDate + ', ' + `${ye}-${mo}-${da}`;

                    }

                    this.gridData = [...this.gridData];
                    count++;
                }, 2000);
                this.newData = true;
            }
            setTimeout(() => {
                this.gridData.sort(this.compare);
                this.filteredData = [...this.gridData];
                this.gridData = [...this.gridData];
                this.newData = true;
                console.log('gridData:' + JSON.stringify(this.gridData));

            }, 2000);

            this.showSpinner = false;
        })
            .catch(error => {
                console.log('getMapDetails error: ' + JSON.stringify(error));
                console.log(error);
            });

        this.newData = true;
        console.log('gridData: ' + JSON.stringify(this.gridData));

    }

    compare(a, b) {

        if (a.lastModifiedDate != null && a.lastModifiedDate > b.lastModifiedDate) {
            return -1;
        }
        if (a.lastModifiedDate != null && a.lastModifiedDate < b.lastModifiedDate) {
            return 1;
        }
        return 0;
    }

    async connectedCallback() {
        this.getUserDetails();

        setTimeout(() => { this.getData(); }, 500);

    }

    // async renderedCallback(){
    //         this.getData();
    // }

    handleSlected() {
        const treegrid = this.template.querySelector('.aldar-lightning-tree-grid');
        const SelectedGridRows = treegrid.getSelectedRows();

        let selectedRows3 = SelectedGridRows.filter((item) => { if (item.level == 2) { return item.column7; } }).map((item) => { return item.column7 });

        // Added by Moh Sarfraj for BPE-75
        this.canProceed = true;
        this.dispatchEvent(new CustomEvent('canproceed', { detail: { canproceed: this.canProceed } }));
        
        // commented by Moh Sarfraj for BPE-75
        // if (SelectedGridRows.length > 1) {
        //     this.canProceed = true;
        //     this.dispatchEvent(new CustomEvent('canproceed', { detail: { canproceed: this.canProceed } }));
        // } else {

        //     this.canProceed = false;
        //     this.dispatchEvent(new CustomEvent('canproceed', { detail: { canproceed: this.canProceed } }));

        // }

        //if(SelectedGridRows.length>0){

        if (selectedRows3.length == 1) {

            this.selectedChildCurrently = selectedRows3[0];
            this.oldChildsSelected = [];
        } else {

            this.oldChildsSelected = selectedRows3.filter((item) => { return item == this.selectedChildCurrently });
            this.selectedChildCurrently = selectedRows3.filter((item) => { return item != this.selectedChildCurrently });


        }

        let oldSelected = treegrid?.selectedRows;
        let selectedCurrently;
        let objSelectedCurrently;




        if (oldSelected != "" && oldSelected != undefined) {
            objSelectedCurrently = SelectedGridRows.filter((item) => {

                return (item.column7 != oldSelected[0] && item.level != 2);

            })[0];
            let filterationResul = SelectedGridRows.filter((item) => {
                return (item.column7 != oldSelected[0] && item.level != 2);
            });
            selectedCurrently = filterationResul.length > 0 ? (filterationResul[0].column7 || filterationResul["column7"]) : "";

        } else {
            objSelectedCurrently = SelectedGridRows[0];
            selectedCurrently = SelectedGridRows[0].column7;
        }

        if (objSelectedCurrently != undefined && objSelectedCurrently.level != 2) {
            this.selectedChildCurrently = "";
            this.gridExpandedRows = [...[]];
            this.selectedRows = [...[]];
            this.selectedChildToTransfer = "";

            this.selectedRows.push(selectedCurrently);
            this.selectedRows = [...this.selectedRows];
            this.gridExpandedRows.push(selectedCurrently);
            this.gridExpandedRows = [...this.gridExpandedRows];
        } else if (objSelectedCurrently == undefined || objSelectedCurrently?.level == 2) {

            if (this.selectedRows.length > 1) {
                this.selectedRows.splice(1, 1);


                this.selectedRows = [...this.selectedRows];
            }
            let childToPush = Array.isArray(this.selectedChildCurrently) ? this.selectedChildCurrently[0] : this.selectedChildCurrently;


            if (childToPush) {
                this.selectedRows.push(childToPush);
                this.selectedRows = [...this.selectedRows];
            }
        }

        if (SelectedGridRows.length > 0) {
            this.selectedItemToTransfer = SelectedGridRows.filter((item) => { return item.column7 == this.selectedRows[0] });
        }




        let hasChildRow = SelectedGridRows.filter((item) => { return item.level == 2; }).length > 0;
        if (hasChildRow) {
            this.selectedChildToTransfer = SelectedGridRows.filter((item) => { return item.column7 == this.selectedRows[1] });

        }


        //This to prevent deselection for parent row.
        if (SelectedGridRows.length == 0) {
            this.selectedRows.push(this.selectedItemToTransfer[0].column7)
            this.selectedRows = [...this.selectedRows];
        }

    }


    goToTheConfirmationStep() {
        // update by Moh Sarfaraj for BPE-75 
        if (this.canProceed || this.selectedRows.length > 0) { //this.selectedRows.length > 1

            const transferDataEvent = new CustomEvent('transferdatafromleadselection', {

                detail: {
                    showConfirmationStep: true, selected: { "parentRow": this.selectedRows[0], "childRow": this.selectedRows[1] },
                    selectedRow: this.selectedItemToTransfer, selectedChildRow: this.selectedChildToTransfer
                }
            });

            this.dispatchEvent(transferDataEvent);
        } else {
            //alert("Please fill or select mandatory fields first.");
            const evt = new ShowToastEvent({
                title: 'Invalid Lead record',
                message: 'Please create a new lead or select lead record under the listed contacts',
                variant: 'warning',
            });
            this.dispatchEvent(evt);
        }
    }


    @api goToTheConfirmationStep2(fromStepperFlag = false) {

        if (this.canProceed || this.selectedRows.length > 1) {

            const transferDataEvent = new CustomEvent('transferdatafromleadselection', {

                detail: {
                    fromStepper: fromStepperFlag, showConfirmationStep: true, selected: { "parentRow": this.selectedRows[0], "childRow": this.selectedRows[1] },
                    selectedRow: this.selectedItemToTransfer, selectedChildRow: this.selectedChildToTransfer
                }
            });

            this.dispatchEvent(transferDataEvent);
        } else {
            alert("Please fill or select mandatory fields first.");
        }
    }
    openModal() {
        //this.sampleMethod();
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
        this.getData();
    }

    /*sampleMethod(event) {
        this.gridColumns[7].cellAttributes.class = 'custom-grid-icon expand-icons'
        //this.gridColumns.pop();
        this.gridColumns = [...this.gridColumns];
    }*/
    get gridDataSize() {
        return this.gridData.length == 0;
    }
}