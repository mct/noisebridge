// vim:set ts=4 sw=4 ai et:

#include <stdio.h>
#include "fann.h"

int main(int argc, char *argv[])
{
    const unsigned int num_input = 28*28;
    const unsigned int num_output = 10;
    const unsigned int num_layers = 3;
    const unsigned int num_neurons_hidden = 80;
    const float desired_error = (const float) 0.001;
    const unsigned int max_epochs = 500000;
    const unsigned int epochs_between_reports = 1; //1000;

    struct fann *ann = fann_create_standard(num_layers, num_input, num_neurons_hidden, num_output);
    fann_set_activation_function_hidden(ann, FANN_SIGMOID_SYMMETRIC);
    fann_set_activation_function_output(ann, FANN_SIGMOID_SYMMETRIC);

    setlinebuf(stdout);
    fann_train_on_file(ann, "t10k-fann-input.dat", max_epochs, epochs_between_reports, desired_error);
    fann_save(ann, "t10k-fann-output.dat");
    fann_destroy(ann);
    return 0;
}
