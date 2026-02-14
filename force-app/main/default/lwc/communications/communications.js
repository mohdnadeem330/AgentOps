import { LightningElement, track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import { NavigationMixin } from 'lightning/navigation';
import getCommunicationInbox from '@salesforce/apex/CommunicationController.getCommunicationInbox';
import getCommunicationOutbox from '@salesforce/apex/CommunicationController.getCommunicationOutbox';
import lightningdatatableHideColumn from '@salesforce/resourceUrl/lightningdatatableHideColumn'
import getUserProfileDetails from '@salesforce/apex/UserProfileController.getUserProfileDetails';
import {loadStyle} from 'lightning/platformResourceLoader'


export default class Communications  extends LightningElement { 

    @track isModalOpen = false;
    //Filter js Start Here//
    buttonClicked;
    @track cssClass = 'filters-items';
    @track iconName = ''; 
    handleToggleClick() {
        this.buttonClicked = !this.buttonClicked;
        this.cssClass = this.buttonClicked ? 'filters-items showfillter' : 'filters-items';
        this.iconName = this.buttonClicked ? 'utility:check' : '';
    } 
    //Filter js End Here// 
    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
    listIcon = resourcesPath + "/ALDARResources/svg/ListIcon.svg";
    @track communicationType = 'Email';
    @track inboxData;
    @track draftData;
    @track sentData;
    @track inboxNewData;
    @track outboxNewData;
    @track draftRecordId;
    @track offenseOptions = [];
    @track profileFlag = false;
    @track communicationTypeEmailFlag = true;
    @track showSpinner = false;
    inboxDataColumns = [
        {
            type: 'text',
            fieldName: 'Title',
            label: 'Subject',
            initialWidth: 200,
            cellAttributes: { class: 'subject-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'CreatedById',
            label: 'From',
            cellAttributes: { class: 'from-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'message',
            label: 'Message',
            cellAttributes: { class: 'received-data-cell' /*important for reponsive */ }
        },
        /*{
            type: 'text',
            fieldName: 'Offense',
            label: 'Offense Type',
            cellAttributes: { class: 'warning-type-cell' }
        },*/
        {
            type: 'text',
            fieldName: 'createdDate',
            label: 'Created Date',
            cellAttributes: { class: 'created-date-cell' /*important for reponsive */ }
        },
        {

            label: 'Actions',
            fieldName: 'view',
            initialWidth: 40,
            type: 'button',
            typeAttributes: {
                iconName: 'action:preview',

                name: 'view',
                title: 'view',
                disabled: false,
                value: 'view'

            },
            cellAttributes: {
                class: 'custom-table-icon view-icon',
                alignment: `center`
            }
        },
        { label: '', fieldName: 'Id', initialWidth: 5, cellAttributes: { class:'column-id' /*important for reponsive */} }
       
    ];

    draftDataColumns = this.draftDataColumns = [
        {
            type: 'text',
            fieldName: 'Title',
            label: 'Subject',
            initialWidth: 200,
            cellAttributes: { class: 'subject-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'message',
            label: 'Message',
            cellAttributes: { class: 'to-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'createdDate',
            label: 'Created Date',
            cellAttributes: { class: 'created-date-cell' /*important for reponsive */ }
        },
        {

            label: 'Actions',
            fieldName: 'edit',
            initialWidth: 40,
            type: 'button',
            typeAttributes: {
                iconName: 'action:edit',

                name: 'Edit',
                title: 'Edit',
                disabled: false,
                value: 'Edit'

            },
            cellAttributes: {
                class: 'custom-table-icon edit-icon',
                alignment: `left`
            }
        },
        { label: '', fieldName: 'Id', initialWidth: 5, cellAttributes: { class:'column-id' /*important for reponsive */} }
    ];

    sentDataColumns = [
        {
            type: 'text',
            fieldName: 'Title',
            label: 'Subject',
            initialWidth: 200,
            cellAttributes: { class: 'subject-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'message',
            label: 'Message',
            cellAttributes: { class: 'to-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'createdDate',
            label: 'Date',
            cellAttributes: { class: 'date-cell' /*important for reponsive */ }
        },
        
        {

            label: 'Actions',
            fieldName: 'actions',
            initialWidth: 100,
            type: 'button',
            typeAttributes: {
                iconName: 'action:preview',

                name: 'view',
                title: 'view',
                disabled: false,
                value: 'view'

            },
            cellAttributes: {
                class: 'custom-table-icon view-icon',
                alignment: `center`
            }
        }
    ];
    
    renderedCallback(){ 
        if(this.isCssLoaded) return
        this.isCssLoaded = true
        loadStyle(this, lightningdatatableHideColumn).then(()=>{
            // console.log("Loaded Successfully");
        }).catch(error=>{ 
            // console.error("Error in loading the css");
        })
    }

    handleCommunicationTypeSelected(event){
        this.communicationType = event.target.value;
        this.communicationTypeEmailFlag = (event.target.value =='Email');
        this.applyFilter();
    }
    
    viewFlag = false;
    composeDraftEmail(event) {
        this.viewFlag = false;
        this.draftRecordId = event.detail.row.id;
        this.isModalOpen = true;
    }
    viewSent(event) {
        this.viewFlag = true;
        this.draftRecordId = event.detail.row.id;
        this.isModalOpen = true;
    }
    viewEmail(event) {
        this.viewFlag = false;
        this.draftRecordId = event.detail.row.id;
        this.isModalOpen = true;
    }
    
    compose() {
        this.viewFlag = false;
        this.draftRecordId = undefined;
        this.isModalOpen = true;
    }

    closeModal(event) {
        this.draftRecordId = undefined;
        this.isModalOpen = event.detail.isOpen;
        console.log();
        if(event.detail.fireRefresh){
            this.initData();
        }
    }

    goToDashboard(){
        window.open('../s', "_self");
    }

    connectedCallback(){
        this.initData();
        setTimeout(() => {
            this.showMessageIfFromDashboard();
        }, 300);
    }

    async initData() {
        this.showSpinner = true;
        this.inboxNewData = await getCommunicationInbox();
        this.outboxNewData = await getCommunicationOutbox();
        const newData = await getUserProfileDetails();
        this.profileFlag = (newData.Profile.Name == 'Agency Admin');
        this.applyFilter();
    }
    clearFilter(){
        let allSearchFields = this.template.querySelectorAll('.filtersVal');
        for(let j = 0; j < allSearchFields.length; j++) {
            allSearchFields[j].value='';
        }
        this.applyFilter();
    }
    applyFilter(){
        let inboxNewTableData = [];
        let drafNewTableData = [];
        let sentNewTableData = [];
        let allOffenseOptions = [];
        let allSearchFields = this.template.querySelectorAll('.filtersVal');


        for (let i = 0; i < this.inboxNewData.length; i++) {
            var recordFiltered=false;
            for(let j = 0; j < allSearchFields.length; j++) {
                
                if(allSearchFields[j].value!=undefined && allSearchFields[j].value!='' ){
                    if(allSearchFields[j].dataset.field =='content' && this.inboxNewData[i].message && (this.inboxNewData[i].message.toLowerCase().search(allSearchFields[j].value.toLowerCase()) == -1 ) ){
                        recordFiltered=true;
                        break;
                    }else if(allSearchFields[j].dataset.field =='content' && this.inboxNewData[i].Title && (this.inboxNewData[i].Title.toLowerCase().search(allSearchFields[j].value.toLowerCase()) == -1 ) ){
                        recordFiltered=true;
                        break;
                    }else  if(allSearchFields[j].dataset.field !='content' && this.inboxNewData[i][allSearchFields[j].dataset.field] != allSearchFields[j].value){
                        recordFiltered=true;
                        break;
                    }
                }
            }
            if(!recordFiltered){
                if (this.inboxNewData[i].Type == this.communicationType) {
                    inboxNewTableData.push(this.inboxNewData[i]);
                }
                if (this.inboxNewData[i].Offense) {
                    allOffenseOptions.push({ label: this.inboxNewData[i].Offense, value: this.inboxNewData[i].Offense });
                }
            }
        }

        for (let i = 0; i < this.outboxNewData.length; i++) {
            var recordFiltered=false;
            for(let j = 0; j < allSearchFields.length; j++) {
                
                if(allSearchFields[j].value!=undefined && allSearchFields[j].value!='' ){
                    if(allSearchFields[j].dataset.field =='content' && this.outboxNewData[i].message && (this.outboxNewData[i].message.toLowerCase().search(allSearchFields[j].value.toLowerCase()) == -1 ) ){
                        recordFiltered=true;
                        break;
                    }else if(allSearchFields[j].dataset.field =='content' && this.outboxNewData[i].Title && (this.outboxNewData[i].Title.toLowerCase().search(allSearchFields[j].value.toLowerCase()) == -1 ) ){
                        recordFiltered=true;
                        break;
                    }else  if(allSearchFields[j].dataset.field !='content' && this.outboxNewData[i][allSearchFields[j].dataset.field] != allSearchFields[j].value){
                        recordFiltered=true;
                        break;
                    }
                }
            }
            if(!recordFiltered){
                if (this.outboxNewData[i].Type == this.communicationType) {
                    if (this.outboxNewData[i].isPublished == true) {
                        sentNewTableData.push(this.outboxNewData[i]);
                    } else {
                        drafNewTableData.push(this.outboxNewData[i]);
                    }
                }
            }

            if (this.outboxNewData[i].Offense) {
                allOffenseOptions.push({ label: this.outboxNewData[i].Offense, value: this.outboxNewData[i].Offense });
            }
        }
        
        this.offenseOptions = this.sortDropDownData(allOffenseOptions,true);
        this.inboxData = inboxNewTableData;
        this.draftData = drafNewTableData;
        this.sentData = sentNewTableData;
        this.showSpinner = false;
    }
  

   
    sortDropDownData(fieldname,noneFlag) {
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
        filteredData.forEach(element => {
            filteredSortedData.push({ label: element.label, value: element.value });
        });

        return filteredSortedData
    }

    showMessageIfFromDashboard() {
        console.log('sessionStorage -> ');
        let cmId = sessionStorage.getItem("communicationId");
        if(cmId!=undefined && cmId!=null && cmId!='null') {
            this.draftRecordId = cmId;
            this.isModalOpen = true;
            this.viewFlag = false;
            this.communicationType = 'Email';
            console.log('showMessageIfFromDashboard -> '+cmId);
            setTimeout(() => {
                sessionStorage.setItem("communicationId", null);
            }, 200);
        }
    }
}