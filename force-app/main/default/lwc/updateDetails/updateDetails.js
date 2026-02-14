import { LightningElement, track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';

export default class UpdateDetails extends LightningElement {


    selectedButn= 'Individual';
    completed = resourcesPath + "/ALDARResources/svg/Completed.svg";
    currentStage = resourcesPath + "/ALDARResources/svg/CurrentStage.svg";
    uploadeFileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";
    deleteFileIcon = resourcesPath + "/ALDARResources/svg/DeleteFileIcon.svg";
    multipleSelection = true;
    isLoaded=false;
    activeSections = [];
    @track uploadedFilesList;

    @track isOrganization=false;

connectedCallback(){
    //this.isLoaded = !this.isLoaded;
    this.dispatchEvent(new CustomEvent('canproceed', {detail: {canproceed:true}}));

    setTimeout(() => {
      //  this.isLoaded = !this.isLoaded;

        //this.hideCompletedandCurrentStages();
        // this.template.querySelectorAll(".current-stage.agency-information-img")[0].style.display = 'inline-block';
        this.openSection("");

    }, 2000);
}


    counter = 0;
    openSection(event) {

     
        let selected = event?.target?.dataset["id"] || event?.currentTarget?.dataset?.id || "PersonalInformation";
        this.counter += 1;


        let selectedIndex = (event?.target?.dataset["leftsideindex"] || event?.currentTarget?.dataset?.leftsideindex) ||
            (event?.target?.dataset["index"] || event?.currentTarget?.dataset?.index) || 1;


        for (let index = 1; index <= 7; index++) {


            if (index < selectedIndex) {
                this.template.querySelectorAll(`[data-leftsideindex="${index}"]`)[0].classList.add("slds-is-completed");
                this.template.querySelectorAll(`[data-notactiveindex="${index}"]`)[0].style.display = 'none';
                this.template.querySelectorAll(`[data-currentstageindex="${index}"]`)[0].style.display = 'none';
                this.template.querySelectorAll(`[data-completedstageindex="${index}"]`)[0].style.display = 'inline-block';
            }

            if (selectedIndex < index) {
                this.template.querySelectorAll(`[data-leftsideindex="${index}"]`)[0].classList.remove("slds-is-completed");
                this.template.querySelectorAll(`[data-leftsideindex="${index}"]`)[0].classList.remove("slds-is-active");
                this.template.querySelectorAll(`[data-notactiveindex="${index}"]`)[0].style.display = 'inline-block';
                this.template.querySelectorAll(`[data-currentstageindex="${index}"]`)[0].style.display = 'none';
                this.template.querySelectorAll(`[data-completedstageindex="${index}"]`)[0].style.display = 'none';

            }

            if (index == selectedIndex) {
                this.template.querySelectorAll(`[data-currentstageindex="${selectedIndex}"]`)[0].style.display = 'inline-block';
                this.template.querySelectorAll(`[data-notactiveindex="${selectedIndex}"]`)[0].style.display = 'none';
                this.template.querySelectorAll(`[data-completedstageindex="${selectedIndex}"]`)[0].style.display = 'none';
                this.template.querySelectorAll(`[data-leftsideindex="${selectedIndex}"]`)[0].classList.add("slds-is-active");

                let scrollToDiv = selected + "ST"
                this.template.querySelectorAll(`[data-scrollto="${scrollToDiv}"]`)[0]?.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });


            }
        }

        // and you have to add  allow-multiple-sections-open to the lightning-accordion html tag

        if (this.multipleSelection) {
            if ((this.counter == 1) || (event?.target?.dataset != undefined && Object.keys(event?.target?.dataset).length != 0)) {
                //for multiple selection
                if (this.activeSections.indexOf(selected) == -1) {

                    this.activeSections = [...this.activeSections, selected];
                } else if (this.activeSections.indexOf(selected) != -1 && (event?.target?.dataset["scrollto"] != undefined && Object.keys(event?.target?.dataset).length != 0)) {

                    this.activeSections.splice(this.activeSections.indexOf(selected), 1);
                    this.activeSections = [...this.activeSections];
                }
            }

        } else {
            this.activeSections = selected; // for one selection
        }

    }

    async openfileUpload(event) {


        function getBase64(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.readAsDataURL(file);
                reader.onload = () => resolve(reader.result);
                reader.onerror = error => reject(error);
            });
        }

        

        await Array.from(event.target.files).forEach(file => {
            var base64;
            getBase64(file).then(
                data => {
                    base64 = data.split(',')[1];
                }
            );

            var reader = new FileReader();

           
                reader.onload = () => {
                    this.uploadedFilesList.push({
                        'filename': file.name,
                        'base64': base64,
                    });
                }
                reader.readAsDataURL(file);

            });

        }

        removeFile(event) {

            let fileName = event.currentTarget.dataset.id;
    
     
                    this.uploadedFilesList = this.goAMLCertificate.filter(function (obj) {
                        return obj.filename != fileName;
                    });
    
                    this.uploadedFilesList = [...this.uploadedFilesList];
                
    
        }
        async openfileUpload(event) {


            function getBase64(file) {
                return new Promise((resolve, reject) => {
                    const reader = new FileReader();
                    reader.readAsDataURL(file);
                    reader.onload = () => resolve(reader.result);
                    reader.onerror = error => reject(error);
                });
            }
    
            //for (let i = 0; i < 5; i++)
    
    
            //const file = event.target.files[0];
    
            await Array.from(event.target.files).forEach(file => {
                var base64;
                getBase64(file).then(
                    data => {
                        base64 = data.split(',')[1];
                    }
                );
    
                var reader = new FileReader();
    
                
                    reader.onload = () => {
                        let result = this.goAMLCertificate.filter(obj => {
    
                            return obj.filename === file.name;
                        });
    
                        this.goAMLCertificate.push({
                            'filename': result?.length > 0 ? file.name + `(${this.goAMLCertificate.length})` : file.name,
                            'base64': base64,
                        });
                    }
                    reader.readAsDataURL(file);
    
                
            });
    
        }

        get checkIndividual(){
            return this.selectedButn == 'Individual' ? 'aldar-btn aldar-btn-black-bg' : 'aldar-btn';
        }

        get checkOrganization(){
            return this.selectedButn == 'Organization' ? 'aldar-btn aldar-btn-black-bg' : 'aldar-btn';
        }


        get acceptedFormats() {
            return ['.pdf', '.png', '.jpg', '.jpeg'];
        }

test="Number 1"
        fun(event){
            this.isOrganization=event?.currentTarget?.dataset?.id === 'Organization';
            this.selectedButn = event?.target?.dataset["id"] || event?.currentTarget?.dataset?.id;
        }
}