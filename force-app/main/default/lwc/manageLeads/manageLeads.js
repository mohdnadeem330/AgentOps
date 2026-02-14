import { api, LightningElement, wire, track } from 'lwc';
import {
    EXAMPLES_COLUMNS_DEFINITION_BASIC,
    EXAMPLES_DATA_BASIC,
} from './sampleData';

import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import getUserDetails from '@salesforce/apex/BrokerLeadController.getUserDetails';
import getLeadsRelatedToContact from '@salesforce/apex/BrokerLeadController.getLeadsRelatedToContact';
import getMapDetails from '@salesforce/apex/BrokerLeadController.getMapDetails';
import getsobjectName from '@salesforce/apex/BrokerLeadController.getsobjectName';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Project_FIELD from '@salesforce/schema/Lead.Project__c';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import { getObjectInfo } from 'lightning/uiObjectInfoApi'; 
import Country_FIELD from '@salesforce/schema/Lead.Nationality__c';
import FORM_FACTOR from '@salesforce/client/formFactor';
import AldarExpertsDesktopLink from '@salesforce/label/c.AldarExpertsDesktopLink';
import PageBlockerEnableButton from '@salesforce/label/c.PageBlockerEnableButton';
// import checkProjectLevelBookingAllowed from '@salesforce/apex/ALD_trailheadappProjectTM_Restriction.allowBookingForSelectedProject';
// import checkUserOnboarded from '@salesforce/apex/ALD_trailheadappOnboardTM_Restriction.checkUserOnboarded';
import { CurrentPageReference } from 'lightning/navigation';
export default class ManageLeads extends NavigationMixin(LightningElement) {

    deviceFormFactor = FORM_FACTOR;
    aldarExpertsDesktopLink = AldarExpertsDesktopLink;
    PageBlockerEnableButton = PageBlockerEnableButton;

    get enablePageBlocker(){
        return this.PageBlockerEnableButton === 'TRUE';
    }

    get isDesktop() {
        return this.deviceFormFactor === 'Large';
    }

    //for Pagination 2 lines 
    currentPage = 1;
    pageSize = 10;
    //Filter js Start Here//

    @track gridColumns = EXAMPLES_COLUMNS_DEFINITION_BASIC;

    // data provided to the tree grid
    @track gridData = []; //EXAMPLES_DATA_BASIC;
    @track newData = false;
    @track gridExpandedRows = [];
    @track arr = [];
    @track toExpandRow = [];
    @track loading = false;
    @track showSpinner = false;
    recordId;
    blockSalesJourney = false;
    blockAppBooking = false;
    generateOffers = resourcesPath + "/ALDARResources/svg/GenerateOffers.svg";
    addLeadIcon = resourcesPath + "/ALDARResources/svg/ListIcon.svg";
    exportIcon = resourcesPath + "/ALDARResources/svg/ExportIcon.svg";
    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @track isModalOpen = false;
    @track filteredData = [];
    @track showAppointmentBookingModal = false;
    showAppointmentCannotbeBookedModal = false;


    @track showDetailsPage = false;
    value = 'inProgress';

    userId = Id;
    @track contactUserId;

    allResult;
    sObjectName;
    agencyName;
    //Filter js Start Here// 
    fillter = resourcesPath + '/ALDARResources/svg/fillter.svg';
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
    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";

    // for initiolization purposes
    get options() {
        return [
            { label: 'New', value: 'new' },
            { label: 'In Progress', value: 'inProgress' },
            { label: 'Finished', value: 'finished' },
        ];
    }

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

    @track nameFilter = '';
    @track emailFilter = '';
    @track mobileFilter = '';
    @track agentFilter = '';
    @track countryFilter = '';
    @track projectFilter = '';

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
        } else if (event.target.dataset.id === 'filterStartDate') {
            this.filterStartDate = value;
        } else if (event.target.dataset.id === 'filterEndDate') {
            this.filterEndDate = value;
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
        this.filterStartDate = undefined;
        this.filterEndDate = undefined;
        let allSearchFields = this.template.querySelectorAll('.leadSearch');
        for (let j = 0; j < allSearchFields.length; j++) {
            allSearchFields[j].value = '';
        }
        this.updateSearch();
    }

    updateSearch() {
        this.getData();
    }
    applyFilters() {

        this.filteredData = this.gridData;
        this.gridExpandedRows = [];
        this.arr = [];
        this.toExpandRow = []

        var regex1 = new RegExp(this.nameFilter, 'i');
        var regex2 = new RegExp(this.emailFilter, 'i');
        var regex3 = new RegExp(this.mobileFilter, 'i');
        var regex4 = new RegExp(this.agentFilter, 'i');
        var regex5 = new RegExp(this.countryFilter, 'i');
        var regex6 = new RegExp(this.projectFilter, 'i');
        var regex7 = new RegExp(this.dateFilter, 'i');

        if (this.nameFilter && this.nameFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex1.test(row.column2) || regex1.test(row.column3) || regex1.test(row.column2 + ' ' + row.column3))
            );
        }
        if (this.emailFilter && this.emailFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex2.test(row.column4))
            );
        }
        if (this.mobileFilter && this.mobileFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex3.test(row.column5))
            );
        }
        if (this.agentFilter && this.agentFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex4.test(row.agentName))
            );
        }
        if (this.countryFilter && this.countryFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex5.test(row.column6))
            );
        }
        if (this.projectFilter && this.projectFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex6.test(row.pjct))
            );
        }
        this.loading = false;
        this.showSpinner = false;
    }

    async expandCollapseRows(event) {

        const treegrid = this.template.querySelector('.aldar-lightning-tree-grid');

        let selectedRow;

        if (this.toExpandRow == undefined || this.toExpandRow == null || this.toExpandRow.length == 0) {
            selectedRow = treegrid.getSelectedRows();
        } else {
            selectedRow = this.toExpandRow;
        }

        //expand row
        selectedRow.forEach(async element => {
            var item = (this.toExpandRow == undefined || this.toExpandRow == null || this.toExpandRow.length == 0) ? element.column0 : element;

            if (this.gridExpandedRows.indexOf(item) == -1) {

                this.gridExpandedRows.push(item);
                this.gridExpandedRows = [...this.gridExpandedRows];
            }
            if (this.arr.indexOf(item) == -1) {
                this.arr.push(item);
            }
        });



        // get array from selected row , becase it's proxy object then it will return array of object,so I'm getting field name to make arr2 as aray of string.
        let arr2 = []
        if (this.toExpandRow == undefined || this.toExpandRow == null || this.toExpandRow.length == 0) {
            arr2 = Array.from(selectedRow).map((item) => { return item.column0 });
        } else {
            arr2 = selectedRow;
        }


        let arr1 = this.arr;
        //getting the difference between what has been clicked and what still is clicked until now. (for more check this
        //:https://stackoverflow.com/questions/1187518/how-to-get-the-difference-between-two-arrays-in-javascript)
        let difference = arr1
            .filter(x => !arr2.includes(x))
            .concat(arr2.filter(x => !arr1.includes(x)));

        // remove items that de selected (collapse row)
        difference.forEach((item) => {
            this.gridExpandedRows.splice(this.gridExpandedRows.indexOf(item), 1);
            this.gridExpandedRows = [...this.gridExpandedRows];
            this.arr.splice(this.arr.indexOf(item), 1);
        });
        this.newData = true;
        this.showSpinner = false;

    }

    async expandCollapseRowsRightSide(event) {

        if (this.toExpandRow.length > 0) {
            this.toExpandRow.map((item) => { return item.column0; });
        }
        if (this.toExpandRow.indexOf(event.detail.row.column0) == -1 && !event.detail.row.isExpanded) {
            this.toExpandRow.push(event.detail.row.column0);
        } else if (this.toExpandRow.indexOf(event.detail.row.column0) != -1 && event.detail.row.isExpanded) {
            this.toExpandRow.splice(this.toExpandRow.indexOf(event.detail.row.column0), 1);
        }
        if (event.detail.action.name === "Expand") {
            this.expandCollapseRows();
        }
        //Tharun changes starts from here - 30 May
        else if (event.detail.action.name === "View") {
            // Onclick of calender icon in row level 2 opens up appointmentBookingModal LWC
            if (event.detail.row.level == 2) {
                if (this.blockSalesJourney) {
                    this.blockAppBooking = true;
                    return;
                }
                else {
                    //childRecordId is selectedLeadId
                    this.childRecordId = event.detail.row.ID;
                    this.trailhead_Project = event.detail.row.trailhead_ProjectName;
                    this.trailhead_feature = 'Book Appointment';

                    // Commented by Moh Sarfaraj for BRP-5539

                    // this.showSpinner = true;
                    //trailhead_Project is sent to apex to consolidate all the assigned trailmixes
                    // await checkUserOnboarded({
                    //     featureSelected: this.trailhead_feature,
                    //     projectName: this.trailhead_Project
                    // })
                    //     .then(result => {
                    //         let userOnboarded = result.userOnboarded;
                    //         if (userOnboarded) {
                    //             this.isBookingAllowed();
                    //         } else {
                    //             this.showSpinner = false;
                    //             this.userTrailMixes = result.onBoardtrailMixRecords;
                    //             this.showAppointmentCannotbeBookedModal = true;
                    //         }
                    //     })
                    //     .catch(error => {
                    //         console.log('error: ' + JSON.stringify(error));
                    //         this.showSpinner = false;
                    //     });

                    this.isBookingAllowed();
                    // this.template.querySelector("c-appointment-booking-modal").recordId=this.childRecordId;
                    //this.showAppointmentBookingModal = true;
                    //this.showAppointmentCannotbeBookedModal = true;
                    return;
                }
            }
            document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', { detail: { showNavigationTab: false, currentStep: "manage-leads" } }));
            this.showDetailsPage = true;
            this.recordId = event.detail.row.column0;
        }
    }

    async isBookingAllowed() {
        // Commented by Moh Sarfaraj for BRP-5539

        // await checkProjectLevelBookingAllowed({
        //     projectName: this.trailhead_Project
        // })
        //     .then(result => {
        //         this.showSpinner = false;
        //         let allowToBook = result.allowBooking;
        //         if (allowToBook) {
        //             this.showAppointmentBookingModal = true;
        //         } else {
        //             this.userTrailMixes = result.trailMixRecords;
        //             this.showAppointmentCannotbeBookedModal = true;
        //         }
        //     })
        //     .catch(error => {
        //         console.log('error: ' + JSON.stringify(error));
        //     });

        this.showAppointmentBookingModal = true;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant

        });
        this.dispatchEvent(event);
    }


    openModal() {
        //  this.sampleMethod();
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
        setTimeout(() => {
            this.getData();
        }, 2000);
    }
    closeModalBooking()
    {
        this.blockAppBooking = false;
    }

    closeAppointmentModal(event) {
        this.showAppointmentBookingModal = event.detail.isOpen;
        if(event.detail.refresh == true){
            setTimeout(() => {
                this.getData();
            }, 2000);
        }
    }
    closeAppointmentCannotBookModal(event) {
        this.showAppointmentCannotbeBookedModal = event.detail.isOpen;
    }
    sampleMethod(event) {
        this.gridColumns[8].cellAttributes.class = 'custom-grid-icon expand-icons'
        //this.gridColumns.pop();
        this.gridColumns = [...this.gridColumns];
    }


    /////////// Ali Changes /////////////////



    connectedCallback() {
        this.showSpinner = true;
        var todayDate = new Date();
        this.filterStartDate = todayDate.getFullYear() + '-01-01'; // updated by Moh Sarfaraj for BPE-71
        // updated by Moh Sarfaraj for BPE-71
        this.filterEndDate = todayDate.getFullYear() + '-' + ((todayDate.getMonth() + 1) < 10 ? `0${(todayDate.getMonth() + 1)}` : (todayDate.getMonth() + 1)) + '-' + ((todayDate.getDate()) < 10 ? `0${todayDate.getDate()}` : todayDate.getDate());
        this.getUserData();
        setTimeout(() => {
            this.performActionsIfClickedFromHomePage();
        }, 400);
    }

    performActionsIfClickedFromHomePage() {
        console.log('Tharun--SessionStorage ---->');
        let fromDashboard = sessionStorage.getItem("dashboardAction");
        if(fromDashboard!=undefined && fromDashboard!=null && fromDashboard!='null') {
            if(fromDashboard === 'openCreateLead'){
                this.openModal();
                console.log('performActionsIfClickedFromHomePage ---> '+fromDashboard);
                setTimeout(() => {
                    sessionStorage.setItem("dashboardAction", null);
                }, 200);
            }
        }
    }

    getUserData() {
        getUserDetails({ userId: this.userId })
            .then(result => {
                this.contactUserId = result.ContactId;
                this.agencyName = result.Contact.Account.Name;
                this.blockSalesJourney = result.Contact.BlockSales__c;
                this.getData();

            })
            .catch(error => {
                console.log('getUserDetails error: ' + JSON.stringify(error));
                this.showSpinner = false;
            });
    }

    getData() {

        this.loading = true;
        this.showSpinner = true;
        this.newData = false;
        this.gridData = [];
        this.filteredData = [];

        getMapDetails({ startDate: new Date(this.filterStartDate), endDate: new Date(this.filterEndDate) })
            .then(result => {
                this.allResult = result;

                for (var i in result) {
                    /*getsobjectName({ recordID: result[i].column0 })
                        .then(data => {
                            objectname = data;
    
                            if (objectname['Lead'] != null) {
                                this.allResult[i].children.push(objectname['Lead']);
                            }
    
                        })
                        .catch(error => {
                            console.log('getsobjectName error: ' + JSON.stringify(error));
                            console.log(error);
                        });*/
                    var tempObj = {
                        column0: result[i].column0,
                        column1: result[i].column1,
                        column2: result[i].column2,
                        column3: result[i].column3,
                        column4: result[i].column4,
                        column5: result[i].column5,
                        column6: result[i].column6,
                        column7: '',
                        column8: result[i].column8,
                        lastModifiedDate: result[i].lastModifiedDate,
                        pjct: result[i].project,
                        rgn: result[i].region,
                        nob: result[i].numberOfBeds,
                        agentName: result[i].agentName,
                        createdDate: result[i].createdDate,
                        leadNumber: '-',
                        _children: []
                    };
                    if (result[i].children) {
                        for (let x = 0; x < result[i].children.length; x++) {
                            let d = new Date(result[i].children[x].CreatedDate);
                            let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(d);
                            let mo = new Intl.DateTimeFormat('en', { month: '2-digit' }).format(d);
                            let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(d);
                            tempObj._children.push({
                                column0: 'Project: ' + result[i].children[x].Project__c,
                                column1: 'Project: ' + result[i].children[x].Project__c,
                                column2: '',
                                ID: result[i].children[x].Id,
                                column3: 'Unit Type: ' + result[i].children[x].UnitType__c,
                                column4: '',
                                column5: 'Created Date & Time: ' + (new Date(result[i].children[x].CreatedDate).toLocaleString()),
                                column6: 'Agent Name: ' + (result[i].children[x].BrokerAgent__c != undefined ? result[i].children[x].BrokerAgent__r.Name : ''),
                                column7: '',
                                column8: 'Project: ' + result[i].children[x].Project__c,
                                //leadNumber : result[i].children[x].LeadNumber__c,
                                sort: 'sort: ' + result[i].children[x].lastModifiedDate,
                                trailhead_ProjectName: result[i].children[x].Project__c,

                            });
                            if (tempObj.createdDate == undefined) {
                                tempObj.createdDate = result[i].children[x].CreatedDate + ', ' + `${ye}-${mo}-${da}`;
                            }
                            if (tempObj.leadNumber == '-') {
                                tempObj.leadNumber = result[i].children[x].LeadNumber__c;
                            }
                        }
                    }


                    this.gridData.push(tempObj);


                }

                this.filteredData = [...this.gridData];
                this.newData = true;
                this.applyFilters();
                //this.filterData();
                /*const startIndex = (this.currentPage - 1) * this.pageSize;
                const endIndex = startIndex + this.pageSize;
                this.filteredData = this.filteredData.slice(startIndex, endIndex);*/

            })
            .catch(error => {
                console.log('getMapDetails error: ' + JSON.stringify(error));
                console.log(error);
                this.filteredData = undefined;
                this.loading = false;
                this.showSpinner = false;
            });

    }



    startDownload() {

        let doc = '<table>';
        doc += '<style>';
        doc += 'table, th, td {';
        doc += '    border: 1px solid black;';
        doc += '    border-collapse: collapse;';
        doc += '    font-weight: normal;';
        doc += '}';
        doc += '</style>';
        doc += '<tr>';
        doc += '<th>Title</th>';
        doc += '<th>First Name</th>';
        doc += '<th>Last Name</th>';
        doc += '<th>Agency Name</th>';
        doc += '<th>Email</th>';
        doc += '<th>Mobile</th>';
        doc += '<th>Property Name</th>';
        doc += '<th>No of Beds</th>';
        doc += '<th>Submitted Date</th>';
        doc += '<th>Events</th>';

        doc += '</tr>';


        for (const i in this.allResult) {

            for (let x = 0; x < this.allResult[i].children.length; x++) {
                doc += '<tr>';
                doc += '<th>' + this.allResult[i].children[x].Salutation + '</th>';
                doc += '<th>' + this.allResult[i].children[x].FirstName + '</th>';
                doc += '<th>' + this.allResult[i].children[x].LastName + '</th>';
                doc += '<th>' + this.agencyName + '</th>';
                doc += '<th>' + this.allResult[i].children[x].Email + '</th>';
                doc += '<th>' + this.allResult[i].children[x].MobileNumber1__c + '</th>';
                doc += '<th>' + this.allResult[i].children[x].Project__c + '</th>';
                doc += '<th>' + this.allResult[i].children[x].NumberOfBedrooms__c + '</th>';
                doc += '<th>' + this.allResult[i].children[x].CreatedDate + '</th>';
                doc += '<th>' + this.allResult[i].children[x].Offer1__c + '</th>';
                doc += '</tr>';
            }
        }

        doc += '</table>';
        var htmlBody = doc;
        var downloadLink = document.createElement("a");
        downloadLink.href = 'data:application/vnd.ms-excel,' + encodeURIComponent(htmlBody);
        downloadLink.target = '_self';
        //downloadLink.download = 'ProtocolRequest_'+date+' '+time+'.xls';

        const date1 = new Date();
        const unixTimeMilSec = date1.toISOString();

        downloadLink.download = this.agencyName + '_' + unixTimeMilSec + '.xls';
        document.body.appendChild(downloadLink);

        downloadLink.click();
    }


    handleCloseDetailPage(event) {
        document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', { detail: { showNavigationTab: true, currentStep: "manage-leads" } }));
        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.showDetailsPage = event.detail.isOpen;

        setTimeout(() => {
            this.getData();
        }, 2000);
    }





    // Pagination : Calculate the total number of pages
    get totalPages() {
        if (this.filteredData != undefined) {
            return Math.ceil(this.filteredData.length / this.pageSize);
        } else {
            return 0;
        }
    }

    // Pagination : Handle "Previous" button click
    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
        //this.filterData();
    }

    // Pagination : Handle "Next" button click
    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
        //this.filterData();
    }

    get filterData() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        return this.filteredData.slice(startIndex, endIndex);
    }
    // Pagination and global search filter 
}