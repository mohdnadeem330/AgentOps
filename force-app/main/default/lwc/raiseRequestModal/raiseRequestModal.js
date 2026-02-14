import { LightningElement, track, wire } from 'lwc';
import getCurrentUserId from "@salesforce/apex/UserService.getCurrentUserId";
import getAccountId from "@salesforce/apex/ContactService.getAccountId";
import saveFiles from '@salesforce/apex/ManageCasesController.saveFiles';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import CATEGORY_FIELD from '@salesforce/schema/Case.Category__c';
import CASE_OBJECT from '@salesforce/schema/Case';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';

export default class RaseRequestModal extends NavigationMixin(LightningElement) {
    userId = Id;

    @track disabledSubmit = false;
    error;
    @track category;
    @track caseNotCreated;
    @track subject;
    @track description;
    @track newComment;
    @track catgoryvalue = '';
    categoryOptions;
    @track accountId;
    fileReaderList = [];
    @track fileNames = '';
    @track uploadedFiles = [];
    @track data;
    @track fileNamesList = [];
    uploadeFileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";
    deleteFileIcon = resourcesPath + "/ALDARResources/svg/DeleteFileIcon.svg";

    @track showSpinner = false;




    connectedCallback() {

        this.showSpinner = true;

        getCurrentUserId({
            currentUserId: this.userId
        }).then(result => {
            this.contactId = result;

            getAccountId({
                contactId: this.contactId
            }).then(result => {
                this.accountId = result;
                this.showSpinner = false;
            }).catch(error => {
                this.showSpinner = false;
                this.error = error;
            })
        }).catch(error => {
            this.showSpinner = false;
            this.error = error;
        })
    }

    //data-id={file.filename}
    removeFile(event) {

        var index = event.currentTarget.dataset.id;
        this.uploadedFiles.splice(index, 1);

        this.fileNamesList.splice(index, 1);

    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false } }));

    }


    handleChangeFields(event) {

        if (event.target.name == 'Category') {
            this.category = event.detail.value;
        }
        if (event.target.name == 'Subject') {
            this.subject = event.target.value;

        }
        if (event.target.name == 'Description') {
            this.description = event.target.value;

        }
        if (event.target.name == 'Comments') {
            this.newComment = event.target.value;

        }

    }

    //GETTING CATEGORY PICKLIST VALUES
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    categoryInfo;

    @wire(getPicklistValues,
        {
            recordTypeId: '$categoryInfo.data.defaultRecordTypeId',
            fieldApiName: CATEGORY_FIELD

        }
    )

    categoryval({ error, data }) {
        if (data) {

            this.categoryOptions = data.values;

        } if (error) {
            console.log('error>>>>', error);
        }
    }

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.gif', '.csv', '.jpeg', '.docx', '.doc', '.xsl'];
    }


    onFileUpload(event) {
        let files = event.target.files;

        if (files.length > 0) {
            let filesName = '';

            for (let i = 0; i < files.length; i++) {
                let file = files[i];

                filesName = filesName + file.name + ',';

                let freader = new FileReader();
                freader.onload = f => {
                    let base64 = 'base64,';
                    let content = freader.result.indexOf(base64) + base64.length;
                    let fileContents = freader.result.substring(content);
                    this.uploadedFiles.push({
                        Title: file.name,
                        VersionData: fileContents
                    });
                };
                freader.readAsDataURL(file);
            }

            this.fileNames = filesName.slice(0, -1);
            this.fileNamesList.push(this.fileNames);

        }



    }

    submitDetails() {
        let getCaseDetails = this.template.querySelector(".casedetails");
        let getSubjectDetails = this.template.querySelector(".subjdetails");
        let getDescriptionDetails = this.template.querySelector(".descdetails");


        if (!this.category) {

            getCaseDetails.setCustomValidity('Category cannot be blank');

        } else if (!this.subject) {

            getSubjectDetails.setCustomValidity('Subject cannot be blank');

        } else if (!this.description) {

            getDescriptionDetails.setCustomValidity('Description cannot be blank');

        } else {

            this.disabledSubmit = true;
            getCaseDetails.setCustomValidity('');
            getSubjectDetails.setCustomValidity('');
            getDescriptionDetails.setCustomValidity('');

            this.caseNotCreated = true;
            var createCase = {
                'sobjectType': 'Case',
                'Subject': this.subject,
                'Description': this.description,
                'Status': 'New',
                'Origin': 'Broker Portal',
                'Account__c': this.accountId,
                'Contact__c': this.contactId,
                'Category__c': this.category

            }

            //save Files and cases 

            this.showSpinner = true;
            saveFiles({
                filesToInsert: this.uploadedFiles,
                caseRec: createCase,
                comment: this.newComment
            }).then(data => {

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        variant: 'success',
                        message: 'Case Successfully created',
                    }),
                );
                this.showSpinner = false;

                console.log('case done');

                //   this.getFilesData(data);

                this.dispatchEvent(new CustomEvent('callgetdata', { detail: ' ' }));

                this.closeModal();

                console.log('diabled submit' + this.disabledSubmit);

            }).catch(error => {
                console.log('error' + error);
                this.showSpinner = false;

            });
        }

        getCaseDetails.reportValidity();
        getSubjectDetails.reportValidity();
        getDescriptionDetails.reportValidity();
    }
}