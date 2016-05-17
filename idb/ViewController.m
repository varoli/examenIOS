//
//  ViewController.m
//  idb
//
//  Created by yoyis on 3/17/16.
//  Copyright (c) 2016 yoyis. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    NSMutableArray *arreglopersonas;
    sqlite3 *dbpersonas;
    NSString *dbruta;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    arreglopersonas = [[NSMutableArray alloc]init];
    [[self barraBuscar]setDelegate:self];
    [[self uilista]setDelegate:self];
    [[self uilista]setDataSource:self];
    [self creaOabredb];
    //self.view.backgroundColor = [UIColor orangeColor];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"nomImagen.extencion"]];
    _uilista.backgroundColor = [UIColor blackColor];
}

-(void)creaOabredb
{
    NSArray *ruta = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *rutadoc = [ruta objectAtIndex:0];
    
    dbruta = [rutadoc stringByAppendingPathComponent:@"alumnos.db"];
    
    char *error;
    
    NSFileManager *filemanager = [NSFileManager defaultManager];
    if (![filemanager fileExistsAtPath:dbruta]) { 
        const char *rutadb = [dbruta UTF8String];
        //crea la bd
        if (sqlite3_open(rutadb, &dbpersonas)==SQLITE_OK) {
            const char *sql_stmt = "CREATE TABLE IF NOT EXISTS STUDENTS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT, LASTNAME TEXT, SEM INTEGER)";
            sqlite3_exec(dbpersonas, sql_stmt, NULL, NULL, &error);
            NSLog(@"Se creo nada");

            sqlite3_close(dbpersonas);
        }else{
            NSLog(@"no se creo nada");
        }
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [arreglopersonas count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellidentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellidentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellidentifier];
    }
    
    persona *apersona = [arreglopersonas objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [apersona.name stringByAppendingString:[@" " stringByAppendingString:apersona.lastname]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d",apersona.group];
    cell.imageView.image = [UIImage imageNamed:@"logo.jpg"];
    
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)agrega:(id)sender {
    char *error;
    if (sqlite3_open([dbruta UTF8String], &dbpersonas)==SQLITE_OK) {
        NSString *inserstmt = [NSString stringWithFormat:@"INSERT INTO STUDENTS(NAME,LASTNAME,SEM) values ('%s','%s','%d')",[self.uinombre.text UTF8String],[self.uiapellidos.text UTF8String],[self.uigrupo.text intValue]];
        const char *insert_stmt = [inserstmt UTF8String];
        NSLog(@"%@",inserstmt);
        if (sqlite3_exec(dbpersonas, insert_stmt, NULL, NULL, &error)==SQLITE_OK) {
            NSLog(@"Alumno agregado");
            
            persona *person = [[persona alloc]init];
            [person setName:self.uinombre.text];
            [person setLastname:self.uiapellidos.text];
            [person setGroup:[self.uigrupo.text intValue]];
            
            [arreglopersonas addObject:person];
        }else{
            NSLog(@"%s",error);}

        sqlite3_close(dbpersonas); 
    }
}


- (IBAction)lista:(id)sender {
    
    sqlite3_stmt *statement;
    
    if (sqlite3_open([dbruta UTF8String], &dbpersonas)==SQLITE_OK) {
        
        [arreglopersonas removeAllObjects];
        
        NSString *querySql = [NSString stringWithFormat:@"SELECT * FROM STUDENTS"];
        const char *query_sql = [querySql UTF8String];
        
        if (sqlite3_prepare(dbpersonas, query_sql, -1, &statement, NULL)==SQLITE_OK) {
            while (sqlite3_step(statement)==SQLITE_ROW) {
                NSString *nombre_str = [[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
                NSString *apellidos_str = [[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 2)];
                NSString *grupo_str = [[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 3)];
                
                persona *person = [[persona alloc]init];
                
                [person setName:nombre_str];	
                [person setLastname:apellidos_str];
                [person setGroup:[grupo_str intValue]];
                
                [arreglopersonas addObject:person];		
            }
        }
        
    }
    
    [[self uilista]reloadData];

}
- (IBAction)elimina:(id)sender {
    [[self uilista]setEditing:!self.uilista.editing animated:YES];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    char *error;

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        persona *person = [arreglopersonas objectAtIndex:indexPath.row];
        
        if(sqlite3_open([dbruta UTF8String], &dbpersonas)==SQLITE_OK){
            NSString *deleteQuery= [NSString stringWithFormat:@"DELETE FROM STUDENTS WHERE LASTNAME = '%s';", [person.lastname UTF8String]];
            const char *deletebd=[deleteQuery UTF8String];
            
            if(sqlite3_exec(dbpersonas, deletebd, NULL, NULL, &error) == SQLITE_OK){
                NSLog(@"Persona eliminada de la abase de datos");
            }
            sqlite3_close(dbpersonas);
        }
        [arreglopersonas removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        /*[self borraP:[NSString stringWithFormat:@"delete from students where name is '%s'",[person.name UTF8String]]];
        [arreglopersonas removeObjectAtIndex:indexPath.row];
        
        [tableView	 deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];*/
    }
}

-(void)borraP:(NSString *)peticionBorrar
{
    char *error;
    
    if (sqlite3_exec(dbpersonas, [peticionBorrar UTF8String], NULL, NULL, &error)==SQLITE_OK) {
        NSLog(@"Alumno borrado");
    }
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [self buscar: [NSString stringWithFormat: @"SELECT * FROM STUDENTS WHERE LASTNAME LIKE '%%%@%%';", searchText]];
}

-(void)buscar:(NSString *)buscarSQL {
    sqlite3_stmt *statement;
    persona *person= nil;
    
    if (sqlite3_open([dbruta UTF8String], &dbpersonas)==SQLITE_OK) {
        [arreglopersonas removeAllObjects];
        
        if (sqlite3_prepare(dbpersonas, [[NSString stringWithFormat: @"%@", buscarSQL] UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                person= [[persona alloc] init];
                [person setName: [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 1)]];
                [person setLastname: [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 2)]];
                [person setGroup:[[[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 3)] intValue]];
                
                [arreglopersonas addObject: person];
            }
        }
    }
    [[self uilista]reloadData];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing: YES];
    [super touchesBegan:touches withEvent:event];
  //  [[self uinombre]resignFirstResponder];
   // [[self uiapellidos]resignFirstResponder];
   // [[self uigrupo]resignFirstResponder];
}

@end
