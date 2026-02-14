import { LightningElement, api, wire, track } from 'lwc';
import getCaseRecord from '@salesforce/apex/CaseService.getCaseRecord';
import getRelatedFilesByCaseId from '@salesforce/apex/ManageCasesController.getRelatedFilesByCaseId';
import getCaseCommentsHistory from '@salesforce/apex/CaseCommentsService.getCaseCommentsHistory';
import createnewComments from '@salesforce/apex/CaseCommentsService.createnewComments';
import getAllContentDocumentLinkRecord from '@salesforce/apex/ContentDocumentLinkService.getAllContentDocumentLinkRecord';
import getFiles from '@salesforce/apex/ManageCasesController.returnFiles';
import createFiles from '@salesforce/apex/ManageCasesController.createFiles';
import getURLPath from '@salesforce/apex/ManageCasesController.getURLPath';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import timeZone from '@salesforce/i18n/timeZone'
import locale from '@salesforce/i18n/locale';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getAttachmentURL from '@salesforce/apex/CaseCommentsService.getAttachmentURL';
export default class CaseDetailScreen extends NavigationMixin(LightningElement) {
    @api recordId;
    displayCaseData;
    displayFileTitle;
    displayCaseHistory;
    filesList = [];
    submittedDate;
    cmtBody;
    firstName;
    lastName;
    @track showUplod = false;
    @track fileNames = '';
    @track uploadedFiles = [];
    @track fileNamesList = [];
    @track commentsData = [];
    @track commentFromField;
    @track isFileUploaded = true;
    @track urlPathPrefix;
    @track disabledSubmit = false;
    @track downloadURL;
    @track openPreview = false;
    @track showSpinner = false;
    uploadeFileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";
    deleteFileIcon = resourcesPath + "/ALDARResources/svg/DeleteFileIcon.svg";
    connectedCallback() {
        this.showSpinner = true;
        this.displayCasRecords();

        getCaseCommentsHistory({
            caseId: this.recordId
        }).then(result => {
            this.displayCaseHistory = result;
            this.displayCaseHistory.forEach(element => {
                let commentHistoryRec = {};
                var dt = element.CreatedDate;

                let dateObj = new Date(dt);

                //  let myDate = (dateObj.getUTCFullYear()) + "-" + (dateObj.getMonth() + 1)+ "-" + (dateObj.getUTCDate());
                let myDate = dateObj.toLocaleString(locale, {
                    "timeZone": timeZone,
                    "dateStyle": 'medium',
                    "timeStyle": 'short',
                });

                commentHistoryRec.cmtBody = element.CommentBody;
                commentHistoryRec.submittedDate = myDate;

                commentHistoryRec.firstName = element.CreatedBy.FirstName;
                commentHistoryRec.lastName = element.CreatedBy.LastName;;

                this.commentsData.push(commentHistoryRec);
            });
            this.showSpinner = false;
        }).catch(error => {
            console.error(error);
            this.showSpinner = false;
        })


        this.displaylistOfFiles();
        this.showSpinner = false;


    }

    async displayCasRecords(event) {
        this.showSpinner = true;
        await getCaseRecord({
            recordId: this.recordId
        }).then(result => {

            this.displayCaseData = result;
            this.displayCaseData.forEach((data => {
                this.commentFromField = data.Description;

            }))
            this.showSpinner = false;
        }).catch(error => {
            console.error(error);
            this.showSpinner = false;
        })
    }



    async displaylistOfFiles(event) {
        this.showSpinner = true;
        //get list of files
        await getURLPath()
            .then(data => {
                this.urlPathPrefix = data;
                this.downloadURL = 'https://' + location.host + '/' + this.urlPathPrefix + '/';

                this.showSpinner = false;
            }).catch(error => {
                window.console.error('error ====> ' + error);
                this.showSpinner = false;
            })

        this.showSpinner = true;
        await getRelatedFilesByCaseId({
            caseId: this.recordId
        }).then(result => {

            let resultdata = JSON.parse(JSON.stringify(result));
            this.filesList = [];
            for (let item of resultdata) {
                let tMap = {
                    "label": item.Title,
                    "value": item.ContentDocumentId,
                    "type": item.ContentDocument.FileType,
                    "latestId": item.ContentDocument.LatestPublishedVersionId,
                    "url": this.downloadURL + 'sfc/servlet.shepherd/document/download/' + item.ContentDocumentId
                };
                this.filesList.push(tMap);
            }
            this.showSpinner = false;
        }).catch(error => {
            console.error(error);
            this.showSpinner = false;
        })

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

            // this.showUplod=false;    
        }


    }

    //calling create files and save cases
    UplodFile() {
        if (!this.uploadedFiles || this.uploadedFiles.length === 0) {
            this.showToast('Error', 'Please Uplod Files', 'error', 'dismissable');
        }
        else {
            this.showSpinner = true;

            this.showUplod = true;
            createFiles({
                filesToInsert: this.uploadedFiles,
                caseId: this.recordId
            }).then(data => {

                this.isFileUploaded = true;
                this.showToast('Success', 'File/s Uploaded Successfully', 'success', 'dismissable');

                this.isFileUploaded = false;

                this.getFilesData(data);
                this.fileNamesList = [];
                this.showSpinner = false;
            }).catch(error => {
                console.error('error' + error);
                this.showSpinner = false;
            });
        }
    }


    getFilesData(lstIds) {
        this.showSpinner = true;
        getFiles({
            lstFileIds: lstIds
        }).then(data => {
            data.forEach((record) => {
                record.FileName = '/' + record.Id;
            });

            this.data = data;
            this.showSpinner = false;
            this.displaylistOfFiles();

            this.dispatchEvent(new CustomEvent('callgetdata', { detail: ' ' }));


        }).catch(error => {
            window.console.error('error ====> ' + error);
            this.showSpinner = false;
        })
    }



    handleComments(event) {
        this.newComment = event.target.value;
    }

    saveComments() {

        let getCaseCommt = this.template.querySelector(".casecomments");
        if (typeof this.newComment === 'undefined') {

            getCaseCommt.setCustomValidity('Please enter comments ');

        }
        else {

            this.disabledSubmit = true;
            getCaseCommt.setCustomValidity('');

            this.showSpinner = true;
            createnewComments({
                caseId: this.recordId,
                comment: this.newComment
            }).then(result => {

                this.showToast('Success', 'Case Comment Successfully added', 'success', 'dismissable');


                this.showSpinner = false;
                this.dispatchEvent(new CustomEvent('callgetdata', { detail: ' ' }));
                this.closeModal();
            }).catch(error => {
                console.error(error);
                this.showSpinner = false;
            })
        } getCaseCommt.reportValidity();
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('callgetdata', { detail: ' ' }));
        this.displaylistOfFiles(); //to refresh page
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false } }));

    }

    removeFile(event) {

        var index = event.currentTarget.dataset.id;
        this.uploadedFiles.splice(index, 1);

        this.fileNamesList.splice(index, 1);

    }


    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.gif', '.csv', '.jpeg', '.docx', '.doc', '.xsl', '.xml', '.ppt'];

    }

    previewHandler(event) {

        var contentDocumentId = event.target.dataset.latestid;

        this.showSpinner = true;
        getAttachmentURL({
            csId: this.recordId,
            cvId: contentDocumentId
        }).then(result => {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: result.DistributionPublicUrl
                }
            }, false);
            this.showSpinner = false;
        }).catch(error => {
            console.error('error>>>', error);
            this.showSpinner = false;
        })
    }

    closePreviewModel(event) {
        this.openPreview = false;
    }

    showToast(title, message, varaint, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: varaint,
            mode: mode
        });
        this.dispatchEvent(event);
    }
}