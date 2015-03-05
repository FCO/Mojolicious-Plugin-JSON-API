#!/usr/bin/perl

package Resource;
use Moose;

has type => (is => "rw", isa => "Str");

around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
 
	$class->$orig(type => $_[0]);
};

package Test;
use Moose;

has bla		=> (is => "rw", isa => "Resource", default => sub{Resource->new("Bla")});
has _ble	=> (is => "rw");

package JSON::API;
use Moose;
my $instance;

sub get_instance {
	my $self ||= bless {}, shift
}

has resources => (
	traits	=> ['Hash'],
	is	=> "ro",
	isa	=> "HashRef[Str]",
	default	=> sub{{}},
	handles	=> {
		set	=> "set"
	}
);

package main;

use Mojolicious::Lite;

app->routes->add_shortcut(resource => sub {
	my $self	= shift;
	my $class	= pop;
	my $name	= shift || lc $class;

	$self->{JSON_API_Resources} ||= JSON::API->get_instance;
	$self->{JSON_API_Resources}->set($name, $class);
	my $under = $self->under("/$name");
	$under->get
		->to(cb => \&load)
		->name("get_list_of_$name")
	;
	$under->post
		->to(cb => \&load)
		->name("post_unexistent_$name")
	;
	$under->put
		->to(cb => \&load)
		->name("put_unexistent_$name")
	;

	my $under_specific = $under->under("/:id")
		->to(cb => \&load)
		->name("get_$name")
	;
	$under_specific->get("/")
		->to(cb => \&load)
		->name("get_$name")
	;
	$under_specific->post("/")
		->to(cb => \&load)
		->name("post_$name")
	;
	$under_specific->put("/")
		->to(cb => \&load)
		->name("put_$name")
	;
	$under_specific->delete("/")
		->to(cb => \&load)
		->name("delete_$name")
	;
	$under_specific->patch("/")
		->to(cb => \&load)
		->name("patch_$name")
	;

	my $meta = $class->meta;
	for my $attr ($meta->get_all_attributes) {
		if ($attr->type_constraint && $attr->type_constraint->is_a_type_of("Resource")) {
			my $attr_name = $attr->name;
			$under_specific->get("/$attr_name")
				->to(cb => \&load)
				->name("get_${name}s_$attr_name")
			;
			$under_specific->post("/$attr_name")
				->to(cb => \&load)
				->name("post_${name}s_$attr_name")
			;
			$under_specific->put("/$attr_name")
				->to(cb => \&load)
				->name("put_${name}s_$attr_name")
			;
			$under_specific->delete("/$attr_name")
				->to(cb => \&load)
				->name("delete_${name}s_$attr_name")
			;
			$under_specific->patch("/$attr_name")
				->to(cb => \&load)
				->name("patch_${name}s_$attr_name")
			;


			my $under_link = $under_specific->under("/links/");
			$under_link->get("/$attr_name")
				->to(cb => \&load)
				->name("get_${name}_links_$attr_name")
			;
			$under_link->post("/$attr_name")
				->to(cb => \&load)
				->name("post_${name}_links_$attr_name")
			;
			$under_link->put("/$attr_name")
				->to(cb => \&load)
				->name("put_${name}_links_$attr_name")
			;
			$under_link->delete("/$attr_name")
				->to(cb => \&load)
				->name("delete_${name}_links_$attr_name")
			;
			$under_link->patch("/$attr_name")
				->to(cb => \&load)
				->name("patch_${name}_links_$attr_name")
			;
		}
	}
	use strict "refs";
});

app->routes->resource("Test");

app->start;
