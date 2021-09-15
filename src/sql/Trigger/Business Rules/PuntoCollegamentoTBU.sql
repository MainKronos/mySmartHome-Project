drop trigger if exists PuntoCollegamentoTBU; -- TBU = trigger before update
delimiter $$
create trigger PuntoCollegamentoTBU
before update on PuntoCollegamento for each row
begin

    declare check_collegamento boolean default FALSE;
    declare error_collegamento varchar(255) default '';

    declare check_tipo boolean default FALSE;
    declare error_tipo varchar(255) default '';

    declare check_punto_cardinale_porta boolean default FALSE;
    declare check_punto_cardinale_finestra boolean default FALSE;
    declare error_punto_cardinale varchar(255) default '';

    set check_collegamento = new.collegamento1 <> new.collegamento2;
    if not check_collegamento then
        select concat('Una ', new.tipo, ' non può collegare una stanza con la stessa stanza.') into error_collegamento;
        signal sqlstate '45000'
        set message_text = error_collegamento;
    end if;

    set check_tipo = new.tipo = 'Porta' or new.tipo = 'Finestra' or new.tipo = 'Portafinestra';
    if not check_tipo then
        select concat('Il tipo del Punto di Collegamento ', new.id_collegamento, ' non è valido, i possibili valori sono: ''Porta'', ''Finestra'', '' Portafinestra''') into error_tipo;
        signal sqlstate '45000'
        set message_text = error_tipo;
    end if;

    set check_punto_cardinale_porta = new.tipo = 'Porta' and new.punto_cardinale is null;
    set check_punto_cardinale_finestra = (new.tipo = 'Finestra' or new.tipo = 'Portafinestra')
        and (new.punto_cardinale = 'N' or new.punto_cardinale = 'NE' or new.punto_cardinale = 'E' or new.punto_cardinale = 'SE' or new.punto_cardinale = 'S' or new.punto_cardinale = 'SW' or new.punto_cardinale = 'W' or new.punto_cardinale = 'NW');

    if new.tipo = 'Porta' and not check_punto_cardinale_porta then
        select concat('Il Punto di Collegamento ', new.tipo, ' non ha un punto cardinale di rifermento e quindi il suo valore deve essere NULL.') into error_punto_cardinale;
        signal sqlstate '45000'
        set message_text = error_punto_cardinale;
    elseif (new.tipo = 'Finestra' or new.tipo = 'Portafinestra') and not check_punto_cardinale_finestra then
        select concat('Il Punto di Collegamento ', new.tipo, ' deve avere un punto cardinale di rifermento (''N'', ''NE'', ''E'', ''SE'', ''S'', ''SW'', ''W'', ''NW'')') into error_punto_cardinale;
        signal sqlstate '45000'
        set message_text = error_punto_cardinale;
    end if;

end $$

update PuntoCollegamento
set id_collegamento=1, punto_cardinale=NULL, collegamento1=1
where id_collegamento=1;