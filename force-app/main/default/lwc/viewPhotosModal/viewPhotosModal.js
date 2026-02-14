import { api, LightningElement, track } from 'lwc';

import dashboardSliderPath from '@salesforce/resourceUrl/DashboardSlider';
import {loadScript,loadStyle} from 'lightning/platformResourceLoader';

import brokerProjectGallery from '@salesforce/apex/ViewPropertiesController.brokerProjectGallery';

export default class ViewPhotosModal extends LightningElement {


    @track modalTitle = "Photo Gallery";
    slideIndex=1;
    @api projectId;
    @api projectName;
    
    @track sliderImaegsArray=[
        // {id:1,index:1, imageSrc:"../resource/ALDARResources/ALDARResources/jpeg/test.jpg" },
        // {id:2,index:2,imageSrc:"../resource/ALDARResources/ALDARResources/jpeg/test2.jpg" },
        // {id:3,index:3,imageSrc:"../resource/ALDARResources/ALDARResources/jpeg/test.jpg"}
                             ];



                            async connectedCallback() {
                                this.modalTitle = this.projectName + ' - Gallery'
                                this.showSpinner = true;
                                await brokerProjectGallery({
                                    projectId: this.projectId
                                }).then(result => {
                                    var count = 1;
                                    result.forEach(val => {
                                        this.sliderImaegsArray.push({id: count, index:count, imageSrc: val});
                                        count++;
                                    })
                                    this.showSpinner = false;
                                }).catch(error => {
                                    this.showSpinner = false;
                                })
                                setTimeout(() => {
                                    //this.initEventTypes();
                                    this.slideIndex = 1;
                                    this.showSlides(this.slideIndex);
                                }, 500);
                            }
                             setBackgroundImage(className) {
                                //console.clear();
                                const divs = this.template.querySelectorAll(`.${className}`);
                                if (divs) {
                                    for (let index = 0; index < divs.length; index++) {
                                        divs[index].style.backgroundImage = divs[index].getAttribute("data-bgimg");
                                        if(index !=0 && className == "mySlides"){
                                        divs[index].style.display="none";
                                    }
                                    }
                                }
                            }

                            async renderedCallback() {
                                // this.template.querySelectorAll('.image-side');
                            //      setTimeout(() => {
                            //     this.setBackgroundImage('image-side');
                            //     this.setBackgroundImage('mySlides');
                            // }, 500);
                        
                                const promise0 = await new Promise((resolve, reject) => {
                                    setTimeout(resolve, 100, loadStyle(this, dashboardSliderPath));
                                });
                              
                                const resourcesToLoad = [promise0];

                                await Promise.all(resourcesToLoad).then(() => {
                                    try {
                                        if (this.calendar) {
                                            this.calendar.destroy();
                                        }
                                    } catch (error) {
                                        console.error('Error calendar init', error);
                                    }
                                }).then(() => {
                                }).catch(error => {
                                    console.error('Error promise all', error);
                                });
                            }
                            plusSlides() {
                                let n = 1;
                                
                                this.showSlides(this.slideIndex += n);
                            }
                          
                            showSlides(n) {
                            
                                var i;
                                var x = this.template.querySelectorAll(".mySlides");
                                var dots = this.template.querySelectorAll(".demo");
                            
                                if (n > x.length) {
                                    this.slideIndex = 1
                                }
                                if (n < 1) {
                                    this.slideIndex = x.length
                                }
                                for (i = 0; i < x.length; i++) {
                                    x[i].style.display = "none";
                                }
                                for (i = 0; i < dots.length; i++) {
                                    dots[i].className = dots[i].className.replace(" w3-white", "");
                                }
                                x[this.slideIndex - 1].style.display = "block";
                                dots[this.slideIndex - 1].className += " w3-white";
                            }
                        
                            goToClickedImage(event){
                                let n=Number(event.target.dataset["index"] || event.currentTarget.dataset.index);
                        
                                var i;
                                var x = this.template.querySelectorAll(".mySlides");
                                var dots = this.template.querySelectorAll(".demo");
                            
                                if (n > x.length) {
                                    this.slideIndex = 1
                                }
                                if (n < 1) {
                                    this.slideIndex = x.length
                                }
                                for (i = 0; i < x.length; i++) {
                                    x[i].style.display = "none";
                                }
                                for (i = 0; i < dots.length; i++) {
                                    dots[i].className = dots[i].className.replace(" w3-white", "");
                                }
                                this.slideIndex=n;
                                x[n - 1].style.display = "block";
                                dots[n - 1].className += " w3-white";
                                
                            }
                            minusSlides() {
                                let n = -1;
                                this.showSlides(this.slideIndex += n);
                              }

                              closeModal(){
                                this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false}}));
                            }

}