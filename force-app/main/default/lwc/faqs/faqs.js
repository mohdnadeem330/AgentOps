import { LightningElement } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';

export default class Faqs extends LightningElement {


    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
    activeSections = [];
    fileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";

    loaded=false;
    array1 = [
     { id: 1, lable: "Category 1",dataId: "category1" },
     { id: 2, lable: "Category 2",dataId: "category2", }, 
     { id: 3, lable: "Category 3",dataId: "category3", }, 
     { id: 4, lable: "Category 4",dataId: "category4", }];

    array2 = [
        {
            id: 1,
            category: "Category 1",
            dataId: "category1",
            // scrollToId:"category1ST",
            questionAndAnswersList:
                [{
                    id: 1.1,
                    index: 1,
                    questionTxt: "This is a placeholder for the question that is supposed to be populated over here?1",
                    answerTxt: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim."

                },
                {
                    id: 1.2,
                    index: 2,
                    questionTxt: "This is a placeholder for the question that is supposed to be populated over here?2",
                    answerTxt: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes,."


                },
                {
                    id: 1.3,
                    index: 3,
                    questionTxt: "This is a placeholder for the question that is supposed to be populated over here?3",
                    answerTxt: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim."


                }

                ]

        },
        {
            id: 2,
            category: "Category 2",
            dataId: "category2",
            // scrollToId:"category2ST",
            questionAndAnswersList:
                [{
                    id: 2.1,
                    index: 1,
                    questionTxt: "This is a placeholder for the question that is supposed to be populated over here?",
                    answerTxt: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim."


                },
                {
                    id: 2.2,
                    index: 1,
                    questionTxt: "This is a placeholder for the question that is supposed to be populated over here?",
                    answerTxt: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes,."


                },
                {
                    id: 2.3,
                    index: 1,
                    questionTxt: "This is a placeholder for the question that is supposed to be populated over here?",
                    answerTxt: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim."


                }

                ]

        },
        {
            id: 3,
            category: "Category 3",
            // scrollToId:"category3ST",
            dataId: "category3",
            questionAndAnswersList:
                [{
                    id: 3.1,
                    index: 1,
                    questionTxt: "This is a placeholder for the question that is supposed to be populated over here?",
                    answerTxt: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim."


                },
                {
                    id: 3.2,
                    index: 1,
                    questionTxt: "This is a placeholder for the question that is supposed to be populated over here?",
                    answerTxt: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes,."


                },
                {
                    id: 3.3,
                    index: 1,
                    questionTxt: "This is a placeholder for the question that is supposed to be populated over here?",
                    answerTxt: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim."


                }

                ]

        },
        {
            id: 4,
            category: "Category 4",
            // scrollToId:"category4ST",
            dataId: "category4",
            questionAndAnswersList:
                [{
                    id: 4.1,
                    index: 1,
                    questionTxt: "This is a placeholder for the question that is supposed to be populated over here?",
                    answerTxt: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim."


                },
                {
                    id: 4.2,
                    index: 1,
                    questionTxt: "This is a placeholder for the question that is supposed to be populated over here?",
                    answerTxt: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes,."


                },
                {
                    id: 4.3,
                    index: 1,
                    questionTxt: "This is a placeholder for the question that is supposed to be populated over here?",
                    answerTxt: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim."


                }

                ]

        }
    ]


    connectedCallback() { 

        this.checkLatestItem();
    }
    renderedCallback() {
        if(!this.loaded){
            this.defaultSelection();

            
            this.loaded=true;
        }
        
    }


    openSection(event) {

        let selected = event?.target?.dataset["id"] || event?.currentTarget?.dataset?.id;
        this.counter += 1;

  


      this.template.querySelectorAll('li').forEach(element => {
       
          if(element.classList.contains("clicked-item")){
            element.classList.remove('clicked-item');
          }
          element.style.backGround="red";
      });
      this.template.querySelector(`[data-id=${selected}]`).classList.add('clicked-item');

      

      
            this.activeSections = selected; // for one selection
       







    }


    defaultSelection(){
      
        let size=this.template.querySelectorAll('li')?.length;
        
        this.template.querySelectorAll('li')[0]?.classList.add('clicked-item');
    }


    
    checkLatestItem(){
setTimeout(() => {
    this.array2.forEach(element => {
        let size=element.questionAndAnswersList.length;
        element.questionAndAnswersList[size-1].latestFlag=true;
    });
}, 1000);

       
        
       
        
    }
}