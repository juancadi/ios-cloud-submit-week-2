//
//  ViewController.swift
//  OpenLibrary
//
//  Created by JUAN ANDRÉS CÁRDENAS DIAZ on 20/12/15.
//  Copyright © 2015 JUAN ANDRÉS CÁRDENAS DIAZ. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var txtFieldISBN: UITextField!
    
  
    @IBOutlet weak var labelNombre: UILabel!
    
    
    @IBOutlet weak var labelAutor: UILabel!
    
    
    @IBOutlet weak var bookSearchLoadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var imgCover: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        txtFieldISBN.delegate = self
        self.bookSearchLoadingIndicator.hidden = true
        self.labelNombre.hidden = true
        self.labelAutor.hidden = true
        self.imgCover.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func textFieldDoneEditing(sender: UITextField) {
        
        sender.resignFirstResponder()
        
        self.labelNombre.hidden = true
        self.labelAutor.hidden = true
        self.imgCover.hidden = true
        
        self.bookSearchLoadingIndicator.hidden = false
        self.bookSearchLoadingIndicator.startAnimating()
        
        var bookInfo = ("","")
        
        if self.txtFieldISBN.text! != ""{
        
            //Función donde se realiza la peticion a OpenLibrary y se procesa la respuesta JSON
            bookInfo = self.getBookInfo(self.txtFieldISBN.text!)
        
            let bookName = bookInfo.0
            let bookAuthor = bookInfo.1
            
            if bookName != "" && bookAuthor != "" {
         
                self.labelNombre.text! = bookName
                self.labelAutor.text! = bookAuthor
                
                self.labelNombre.hidden = false
                self.labelAutor.hidden = false
            
            }else{
                
                self.showSingleAlert("ERROR", message: "Se presento un problema estableciendo comunicación con openlibrary.org, por favor verifique el ISBN ingresado!")
            }
            
            
        }else{
            
            self.showSingleAlert("Info...", message: "Por favor ingrese el ISBN del libro que desea buscar.")
        }
        
        self.bookSearchLoadingIndicator.stopAnimating()
        self.bookSearchLoadingIndicator.hidden = true

    }

    @IBAction func backgroundTap(sender: UIControl) {
        
        txtFieldISBN.resignFirstResponder()
    }
    
    
    //Se realiza petición a OpenLibrary, se procesa respuesta y se descarga imagen de la porttada en caso de que exista
    func getBookInfo(isbn : String)->(bookName : String, bookAuthors : String){
    
        let stringUrl = "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=\(isbn)"
        let url = NSURL(string: stringUrl)
        let datos : NSData? = NSData(contentsOfURL: url!)
        var responseData : NSString?
        var response = ("","")
        
        if datos != nil {
            
            responseData = NSString(data: datos!, encoding: NSUTF8StringEncoding)
            print("Respuesta obtenida desde openlibrary.org: \n\t \(responseData!)")
            
            if responseData != "{}" {

            
            do{
                let jsonResponse = try NSJSONSerialization.JSONObjectWithData(datos!, options: NSJSONReadingOptions.MutableLeaves)
                
                let responseObject = jsonResponse as! NSDictionary
                let infoBook = responseObject["\(isbn)"]! as! NSDictionary
                
                //Se extrae el titulo
                let titulo = infoBook["title"]! as! NSString as String
                
                var names = ""
                
                //Se extrae nombre de los autores
                if let autores = infoBook["authors"] as? [[String: AnyObject]] {
                    for autor in autores {
                        if let name = autor["name"] as? String {
                            names += "\(name), "
                        }
                    }
                
                }
                
                //Se descarga portada si exuiste alguna asociada al libro
                if let covers = infoBook.valueForKey("cover"){
                    
                    let urlCover = covers["medium"]! as! NSString as String
                    print("URL COVER: \(urlCover)")
                    
                    imageForImageURLString(urlCover) { (image, success) -> Void in
                        if success {
                            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                                guard let image = image
                                    else { return } // gestion de errrores en caso de ser necesario
                                
                                // Se recarga la imagen de la portada
                                self.imgCover.image = image
                                self.imgCover.hidden = false
                                
                            }
                        } else {
                            // gestion de errrores en caso de ser necesario
                        }
                    }
                
                }else{
                
                    self.imgCover.image = UIImage(named: "no_disponible");
                
                }
                
                response =  (titulo, names.substringToIndex(names.endIndex.advancedBy(-2)))

            
            }catch _{
            
                print("Error Serializando JSON")
                //alert
                self.showSingleAlert("ERROR", message: "Se presento un problema estableciendo comunicación con openlibrary.org")

            }
            
        }
    
        }
        

        return response
    }
    
    func showSingleAlert(title:String, message:String){
    
        let alert = UIAlertView()
        alert.title = title
        alert.message = message
        alert.addButtonWithTitle("OK")
        alert.show()
    
    }
    
    //Funcion auxiliar para descargar imagenes
    func imageForImageURLString(imageURLString: String, completion: (image: UIImage?, success: Bool) -> Void) {
        guard let url = NSURL(string: imageURLString),
            let data = NSData(contentsOfURL: url),
            let image = UIImage(data: data)
            else {
                completion(image: nil, success: false);
                return
        }
        
        completion(image: image, success: true)
    }

}

