function CheckBoxValueFcn(app, event)
    
       app.CustomFileName.Visible = event.Source.Visible;
       app.CustomFileNameLabel.Visible = event.Source.Visible;
            
  end